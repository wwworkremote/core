# frozen_string_literal: true

require "faraday"

# Service to extract and summarize technical context from a user's GitHub profile.
# It builds a technical proof profile used by the ProfileMatcher for deep alignment.
class LLM::GithubProcessor
  GITHUB_API = "https://api.github.com"

  def self.call(profile)
    new(profile).call
  end

  def initialize(profile)
    @profile = profile
    @username = profile.github_url&.split("/")&.last
    @conn = Faraday.new(url: GITHUB_API) do |f|
      f.request :json
      # Add auth token if available in credentials or ENV
      token = Rails.application.credentials[:github_token] || ENV.fetch("GITHUB_TOKEN", nil)
      f.headers["Authorization"] = "token #{token}" if token
      f.headers["Accept"] = "application/vnd.github.v3+json"
    end
  end

  def call
    return { success: false, error: "No GitHub username found." } unless @username

    # 1. Fetch Repositories
    repos = fetch_repos

    # 2. Extract READMEs for top repos
    repo_details = repos.first(5).map do |repo|
      {
        name: repo["name"],
        description: repo["description"],
        language: repo["language"],
        readme: fetch_readme(repo["name"])
      }
    end

    # 3. Use LLM to synthesize technical context
    synthesis = synthesize_technical_profile(repo_details)

    if synthesis
      @profile.update!(github_context: {
                         repos: repo_details.map { |r| r.except(:readme) },
                         synthesis: synthesis,
                         last_synced_at: Time.current
                       })
      { success: true }
    else
      { success: false, error: "LLM synthesis failed." }
    end
  end

  private

  def fetch_repos
    response = @conn.get("/users/#{@username}/repos", { sort: "updated", per_page: 20 })
    return [] unless response.success?
    JSON.parse(response.body)
  end

  def fetch_readme(repo_name)
    response = @conn.get("/repos/#{@username}/#{repo_name}/readme")
    return nil unless response.success?

    content = JSON.parse(response.body)["content"]
    Base64.decode64(content).force_encoding("UTF-8") rescue nil
  end

  def synthesize_technical_profile(repo_details)
    prompt = <<~PROMPT
      [SYSTEM_OBJECTIVE]
      Analyze the following GitHub repository data for developer @#{@username}.
      Extract 'Technical Proof' points: specific frameworks, architectural patterns,#{' '}
      and complexity levels demonstrated in the code.

      [REPOSITORIES]
      #{repo_details.map { |r| "### #{r[:name]} (#{r[:language]})\n#{r[:description]}\nREADME: #{r[:readme]&.truncate(2000)}" }.join("\n\n")}

      [OUTPUT_FORMAT]
      1. **CORE_STACK**: Dominant languages and frameworks.
      2. **ARCHITECTURAL_PREFERENCES**: (e.g., TDD, Microservices, Domain-Driven Design).
      3. **COMPLEXITY_EVIDENCE**: Specific hard technical problems solved.
      4. **PROJECT_HIGHLIGHTS**: 3 sentences summarizing the best work.
    PROMPT

    result = LLM::Orchestrator.call(
      untrusted_text: prompt,
      system_rules: "You are an elite technical recruiter and code auditor.",
      task_instructions: "Return a concise, high-signal technical synthesis."
    )

    result[:success] ? result[:output] : nil
  end
end
