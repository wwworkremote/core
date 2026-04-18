# frozen_string_literal: true

module JobBoards
  class Categorizer
    CATEGORIES = [
      'Software Engineering',
      'Data Science',
      'Product Management',
      'Design',
      'Marketing',
      'Sales',
      'Customer Support',
      'Operations',
      'Other'
    ].freeze

    def initialize(job_posting)
      @job_posting = job_posting
    end

    def call
      system_rules = "You are a professional job categorizer. Return ONLY valid JSON."
      task_instructions = <<~INST
        Task: Categorize the following job posting.
        The "category" MUST be exactly one of: #{CATEGORIES.join(', ')}.
        If unsure, use "Other".
        The "tags" should be 1-5 technical keywords.
        Return ONLY valid JSON. No preamble, no explanation.

        Expected JSON Format:
        {"category": "Software Engineering", "tags": ["ruby", "rails"]}
      INST

      result = Llm::Orchestrator.call(
        system_rules: system_rules,
        task_instructions: task_instructions,
        untrusted_text: @job_posting.body&.truncate(3000),
        schema: { 'category' => String, 'tags' => Array }
      )

      if result[:success]
        parsed = parse_response(result[:output])
        if parsed
          @job_posting.update(
            tags: parsed['tags'],
            data: @job_posting.data.merge('ai_category' => parsed['category'])
          )
        end
      else
        Rails.logger.error "[Categorizer] Orchestrator failed for Job #{@job_posting.id}: #{result[:error]}"
      end
    end

    private

    def parse_response(response)
      # Basic JSON extraction in case the LLM adds chatter
      json_match = response.match(/\{.*\}/m)
      return nil unless json_match

      JSON.parse(json_match[0])
    rescue JSON::ParserError
      nil
    end
  end
end
