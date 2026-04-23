# frozen_string_literal: true

module JobBoards
  class CategorizerAgent < RubyLLM::Agent
    # The instructions macro will look for:
    # app/prompts/job_boards/categorizer_agent/instructions.txt.erb
    instructions

    def call(job_posting)
      # We delegate to the orchestrator to wrap this agent in guardrails
      LLM::Orchestrator.call(
        agent: self,
        untrusted_text: job_posting.body&.truncate(4000),
        schema: {
          'category' => String,
          'tags' => Array,
          'is_remote' => :boolean,
          'remote_nuance' => String,
          'salary_min' => :integer,
          'salary_max' => :integer,
          'currency' => String
        },
        metadata: { 'job_posting_id' => job_posting.id }
      )
    end
  end
end
