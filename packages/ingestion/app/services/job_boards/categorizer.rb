# frozen_string_literal: true

class JobBoards::Categorizer
  CATEGORIES = [
    "Software Engineering",
    "Data Science",
    "Product Management",
    "Design",
    "Marketing",
    "Sales",
    "Customer Support",
    "Operations",
    "Other"
  ].freeze

  OPTIONAL_CATEGORIZATION_KEYS = %w[is_remote remote_nuance salary_min salary_max currency].freeze

  def initialize(job_posting)
    @job_posting = job_posting
  end

  def call(force: false)
    return if skip?(force)

    result = JobBoards::CategorizerAgent.new.call(@job_posting)
    result[:success] ? apply_result(result[:output]) : log_failure(result[:error])
  end

  private

  def skip?(force)
    return false if force

    # Skip if already categorized (to save local LLM tokens/resources), or if
    # expired/stale (shield against wasted categorization work)
    @job_posting.data["ai_category"].present? || @job_posting.expired?
  end

  def apply_result(output)
    parsed = parse_response(output)
    return unless parsed

    @job_posting.update(tags: parsed["tags"], data: @job_posting.data.merge(categorization_fields(parsed)))
  end

  def categorization_fields(parsed)
    { "ai_category" => parsed["category"] }.merge(optional_categorization_fields(parsed))
  end

  def optional_categorization_fields(parsed)
    OPTIONAL_CATEGORIZATION_KEYS.index_with { |key| parsed[key] }
  end

  def log_failure(error)
    Rails.logger.error "[Categorizer] Agent failed for Job #{@job_posting.id}: #{error}"
  end

  def parse_response(response)
    return nil if response.blank?

    json_source = extract_json(response)
    json_source ? JSON.parse(json_source) : nil
  rescue JSON::ParserError
    nil
  end

  # Basic JSON extraction in case the LLM adds chatter
  def extract_json(response)
    response.match(/\{.*\}/m)&.to_s
  end
end
