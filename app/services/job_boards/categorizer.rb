# frozen_string_literal: true

class JobBoards::Categorizer
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
    # Skip if already categorized unless forced (to save local LLM tokens/resources)
    return if @job_posting.data['ai_category'].present?

    agent = JobBoards::CategorizerAgent.new
    result = agent.call(@job_posting)

    if result[:success]
      parsed = parse_response(result[:output])
      if parsed
        @job_posting.update(
          tags: parsed['tags'],
          data: @job_posting.data.merge(
            'ai_category' => parsed['category'],
            'is_remote' => parsed['is_remote'],
            'remote_nuance' => parsed['remote_nuance'],
            'salary_min' => parsed['salary_min'],
            'salary_max' => parsed['salary_max'],
            'currency' => parsed['currency']
          )
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
