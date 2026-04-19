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
      agent = JobBoards::CategorizerAgent.new
      result = agent.call(@job_posting)

      if result[:success]
        parsed = parse_response(result[:output])
        if parsed
          @job_posting.update(
            tags: parsed['tags'],
            data: @job_posting.data.merge('ai_category' => parsed['category'])
          )
        end
      else
        Rails.logger.error "[Categorizer] Agent failed for Job #{@job_posting.id}: #{result[:error]}"
      end
    end

    private

    def parse_response(response)
      return nil if response.blank?

      # Basic JSON extraction in case the LLM adds chatter
      json_match = response.match(/\{.*\}/m)
      return nil unless json_match

      JSON.parse(json_match[0])
    rescue JSON::ParserError
      nil
    end
  end
end
