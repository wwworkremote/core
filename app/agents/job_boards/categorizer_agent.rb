# frozen_string_literal: true

class JobBoards::CategorizerAgent < RubyLLM::Agent
  # The instructions macro will look for:
  # app/prompts/job_boards/categorizer_agent/instructions.txt.erb
  instructions

  # One cohesive orchestrator call -- splitting it further would obscure
  # it, not simplify it.
  # rubocop:disable Metrics/MethodLength
  def call(job_posting)
    # We delegate to the orchestrator to wrap this agent in guardrails
    LLM::Orchestrator.call(
      agent: self,
      untrusted_text: job_posting.body&.truncate(4000),
      schema: categorization_schema,
      metadata: { "job_posting_id" => job_posting.id }
    )
  end
  # rubocop:enable Metrics/MethodLength

  private

  # One cohesive schema definition -- splitting it further would
  # obscure it, not simplify it.
  # rubocop:disable Metrics/MethodLength
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
  # rubocop:enable Metrics/MethodLength
end
