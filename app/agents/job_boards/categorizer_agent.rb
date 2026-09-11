# frozen_string_literal: true

class JobBoards::CategorizerAgent < RubyLLM::Agent
  PROMPT_KEY = "job_boards_categorizer"

  # One cohesive orchestrator call -- splitting it further would obscure
  # it, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def call(job_posting)
    # We delegate to the orchestrator to wrap this agent in guardrails
    LLM::Orchestrator.call(
      agent: self,
      untrusted_text: job_posting.body&.truncate(4000),
      schema: categorization_schema,
      metadata: { "job_posting_id" => job_posting.id }
    )
  end

  # LLM::Orchestrator#default_task_instructions calls this when a caller
  # doesn't pass task_instructions: explicitly (see #call above) -- this
  # is the actual prompt the categorization LLM call runs on. Admin-editable
  # via PipelinePrompt (key: "job_boards_categorizer"); falls back to
  # app/prompts/job_boards/categorizer_agent/instructions.txt.erb when no
  # active override exists.
  def render_instructions
    PipelinePrompt.render_for(PROMPT_KEY) { default_instructions }
  end

  private

  def default_instructions
    path = Rails.root.join("app/prompts/job_boards/categorizer_agent/instructions.txt.erb")
    ERB.new(File.read(path)).result(binding)
  end

  # One cohesive schema definition -- splitting it further would
  # obscure it, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def categorization_schema
    {
      "category" => String,
      "tags" => Array,
      "is_remote" => :boolean,
      "remote_nuance" => String,
      "salary_min" => :integer,
      "salary_max" => :integer,
      "currency" => String
    }
  end
end
