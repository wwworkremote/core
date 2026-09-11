# frozen_string_literal: true

# Produces the application angle (which resume track to lead with, talking
# points) and a company research summary for a captured JobPosting. Fit
# scoring/confidence is deliberately NOT this agent's job -- that's already
# covered by LLM::ProfileMatcher, whose output (UserJobPosting#match_analysis)
# is passed in here as context, when available, rather than re-derived.
class JobBoards::StrategyAgent < RubyLLM::Agent
  PROMPT_KEY = "job_boards_strategy"

  # One cohesive orchestrator call -- splitting it further would obscure
  # it, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def call(job_posting, user_job_posting)
    result = LLM::Orchestrator.call(
      agent: self,
      untrusted_text: build_context(job_posting, user_job_posting),
      schema: strategy_schema,
      metadata: { "job_posting_id" => job_posting.id, "user_job_posting_id" => user_job_posting.id }
    )
    persist_result(user_job_posting, result)
    result
  end

  # LLM::Orchestrator#default_task_instructions calls this when a caller
  # doesn't pass task_instructions: explicitly -- admin-editable via
  # PipelinePrompt (key: "job_boards_strategy"), falls back to
  # app/prompts/job_boards/strategy_agent/instructions.txt.erb.
  def render_instructions
    PipelinePrompt.render_for(PROMPT_KEY) { default_instructions }
  end

  private

  def build_context(job_posting, user_job_posting)
    <<~CTX
      JOB POSTING: #{job_posting.title} at #{company_name(job_posting)}
      #{job_posting.body&.truncate(4000)}

      EXISTING FIT ANALYSIS:
      #{user_job_posting.match_analysis.presence || '(not yet available)'}

      COMPANY RESEARCH ON FILE:
      #{company_research_summary(job_posting)}
    CTX
  end

  def company_name(job_posting)
    job_posting.company&.name || job_posting.company_name
  end

  def company_research_summary(job_posting)
    job_posting.company&.glassdoor_data.to_h.dig("reputation_audit", "summary") || "(none on file)"
  end

  def default_instructions
    path = Rails.root.join("app/prompts/job_boards/strategy_agent/instructions.txt.erb")
    ERB.new(File.read(path)).result(binding)
  end

  # rubocop:disable-next Metrics/MethodLength
  def strategy_schema
    {
      "resume_track" => String,
      "talking_points" => Array,
      "company_research_summary" => String,
      "key_risks" => Array
    }
  end

  def persist_result(user_job_posting, result)
    return unless result[:success]

    parsed = parse_output(result[:output]).merge("generated_at" => Time.current)
    user_job_posting.update!(strategy: user_job_posting.strategy.to_h.merge(parsed))
  end

  def parse_output(output)
    JSON.parse(output)
  rescue JSON::ParserError
    {}
  end
end
