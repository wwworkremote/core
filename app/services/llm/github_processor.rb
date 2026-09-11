# frozen_string_literal: true

require "faraday"

# Service to extract and summarize technical context from a user's GitHub profile.
# It builds a technical proof profile used by the ProfileMatcher for deep alignment.
class LLM::GithubProcessor
  GITHUB_API = "https://api.github.com"
  SYSTEM_RULES = "You are an elite technical recruiter and code auditor."
  TASK_INSTRUCTIONS = "Return a concise, high-signal technical synthesis."

  def self.call(profile)
    new(profile).call
  end

  def initialize(profile)
    @profile = profile
    @username = profile.github_url&.split("/")&.last
    @conn = build_connection
  end

  def call
    return { success: false, error: "No GitHub username found." } unless @username

    synthesize_and_persist
  end

  private

  def synthesize_and_persist
    repo_details = fetch_repo_details
    synthesis = synthesize_technical_profile(repo_details)
    return { success: false, error: "LLM synthesis failed." } unless synthesis

    persist_synthesis(repo_details, synthesis)
    { success: true }
  end

  def build_connection
    Faraday.new(url: GITHUB_API) do |f|
      f.request :json
      f.headers["Authorization"] = "token #{auth_token}" if auth_token
      f.headers["Accept"] = "application/vnd.github.v3+json"
    end
  end

  # Auth token from credentials or ENV, if available
  def auth_token
    Rails.application.credentials[:github_token] || ENV.fetch("GITHUB_TOKEN", nil)
  end

  def fetch_repo_details
    fetch_repos.first(5).map { |repo| repo_detail(repo) }
  end

  def repo_detail(repo)
    { name: repo["name"], description: repo["description"], language: repo["language"],
      readme: fetch_readme(repo["name"]) }
  end

  def persist_synthesis(repo_details, synthesis)
    @profile.update!(github_context: {
                       repos: repo_details.map { |r| r.except(:readme) },
                       synthesis: synthesis,
                       last_synced_at: Time.current
                     })
  end

  def fetch_repos
    response = @conn.get("/users/#{@username}/repos", { sort: "updated", per_page: 20 })
    return [] unless response.success?

    JSON.parse(response.body)
  end

  def fetch_readme(repo_name)
    response = @conn.get("/repos/#{@username}/#{repo_name}/readme")
    return nil unless response.success?

    decode_readme(JSON.parse(response.body)["content"])
  end

  def decode_readme(content)
    Base64.decode64(content).force_encoding("UTF-8")
  rescue StandardError
    nil
  end

  def synthesize_technical_profile(repo_details)
    result = LLM::Orchestrator.call(untrusted_text: build_prompt(repo_details), system_rules: SYSTEM_RULES,
                                    task_instructions: TASK_INSTRUCTIONS)
    result[:success] ? result[:output] : nil
  end

  def build_prompt(repo_details)
    <<~PROMPT
      [SYSTEM_OBJECTIVE]
      Analyze the following GitHub repository data for developer @#{@username}.
      Extract 'Technical Proof' points: specific frameworks, architectural patterns,#{' '}
      and complexity levels demonstrated in the code.

      [REPOSITORIES]
      #{repo_summaries(repo_details)}

      [OUTPUT_FORMAT]
      1. **CORE_STACK**: Dominant languages and frameworks.
      2. **ARCHITECTURAL_PREFERENCES**: (e.g., TDD, Microservices, Domain-Driven Design).
      3. **COMPLEXITY_EVIDENCE**: Specific hard technical problems solved.
      4. **PROJECT_HIGHLIGHTS**: 3 sentences summarizing the best work.
    PROMPT
  end

  def repo_summaries(repo_details)
    repo_details.map { |r| repo_summary(r) }.join("\n\n")
  end

  def repo_summary(repo)
    "### #{repo[:name]} (#{repo[:language]})\n#{repo[:description]}\nREADME: #{repo[:readme]&.truncate(2000)}"
  end
end
