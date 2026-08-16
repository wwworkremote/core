# frozen_string_literal: true

# Applies an on-demand AI reformat of one JobPosting's description, storing
# the result in data["formatted_body"] -- body itself is never touched, so
# the raw original stays the source of truth (same convention as
# JobBoards::Categorizer's ai_category/is_remote fields).
class JobBoards::Reformatter
  def initialize(job_posting)
    @job_posting = job_posting
  end

  def call
    result = JobBoards::ReformatterAgent.new.call(@job_posting)
    result[:success] ? apply_result(result[:output]) : log_failure(result[:error])
  ensure
    clear_pending_flag
  end

  private

  def apply_result(output)
    return if output.blank?

    @job_posting.update(data: @job_posting.data.merge("formatted_body" => output.to_s.strip))
  end

  def clear_pending_flag
    return unless @job_posting.data["reformatting"]

    @job_posting.update(data: @job_posting.data.merge("reformatting" => false))
  end

  def log_failure(error)
    Rails.logger.error "[Reformatter] Agent failed for Job #{@job_posting.id}: #{error}"
  end
end
