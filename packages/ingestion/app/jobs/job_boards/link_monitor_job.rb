# frozen_string_literal: true

class JobBoards::LinkMonitorJob < ApplicationJob
  queue_as :light
  lightweight!
  idempotent!

  def perform(limit: 100)
    targets(limit).each { |job| check_link(job) }
  end

  private

  # Check active job postings that haven't been checked recently
  def targets(limit)
    JobPosting.where.not(status: "archived")
              .where(target_url: present_urls)
              .order(Arel.sql("RANDOM()"))
              .limit(limit)
  end

  def present_urls
    # Ensure we only check jobs with URLs
    JobPosting.where.not(target_url: [nil, ""]).select(:target_url)
  end

  def check_link(job)
    handle_response(job, fetch_head(job.target_url))
  rescue Faraday::Error => e
    # If the site is down or timing out, we don't archive immediately,
    # but we log the attempt.
    log_connection_failure(job, e)
  rescue StandardError => e
    log_unexpected_error(job, e)
  end

  def log_connection_failure(job, error)
    Rails.logger.warn "[LinkMonitor] Connection failed for Job #{job.id}: #{error.message}"
  end

  def log_unexpected_error(job, error)
    Rails.logger.error "[LinkMonitor] Unexpected error for Job #{job.id}: #{error.message}"
  end

  def fetch_head(url)
    Faraday.head(url) do |req|
      req.options.timeout = 5
      req.options.open_timeout = 2
    end
  end

  def handle_response(job, response)
    case response.status
    when 404 then archive_job(job, "Link returned 404 (Not Found)")
    when 301, 302 then handle_redirect(job, response)
    end
  end

  # Follow a redirect once to see if it leads to an "expired" page
  def handle_redirect(job, response)
    follow_up = Faraday.get(response.headers["location"])
    return unless expired_posting?(follow_up.body)

    archive_job(job, "Job no longer available (Redirect signal)")
  end

  def expired_posting?(body)
    text = body.downcase
    text.include?("job is no longer available") || text.include?("position has been filled")
  end

  def archive_job(job, reason)
    return unless job.may_archive?

    Rails.logger.info "[LinkMonitor] Archiving Job #{job.id}: #{reason}"
    job.archive!
    job.pipeline_steps.create!(status: "archived", note: "[SYSTEM_MONITOR] #{reason}")
  end
end
