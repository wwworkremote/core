# frozen_string_literal: true

class JobBoards::ReformatterAgent < RubyLLM::Agent
  PROMPT_KEY = "job_boards_reformatter"

  # We delegate to the orchestrator to wrap this agent in guardrails, same
  # as JobBoards::CategorizerAgent -- untrusted scraped text always routes
  # through Guardrails::Pipeline, never straight to RubyLLM.
  def call(job_posting)
    LLM::Orchestrator.call(
      agent: self,
      untrusted_text: job_posting.body&.truncate(8000),
      metadata: { "job_posting_id" => job_posting.id }
    )
  end

  # LLM::Orchestrator#default_task_instructions calls this when a caller
  # doesn't pass task_instructions: explicitly (see #call above). Admin-
  # editable via PipelinePrompt (key: "job_boards_reformatter"); falls back
  # to app/prompts/job_boards/reformatter_agent/instructions.txt.erb when no
  # active override exists.
  def render_instructions
    PipelinePrompt.render_for(PROMPT_KEY) { default_instructions }
  end

  private

  def default_instructions
    path = Rails.root.join("app/prompts/job_boards/reformatter_agent/instructions.txt.erb")
    ERB.new(File.read(path)).result(binding)
  end
end
