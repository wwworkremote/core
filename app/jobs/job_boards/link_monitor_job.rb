# frozen_string_literal: true

class JobBoards::LinkMonitorJob < ApplicationJob
  queue_as :light
  lightweight!
  idempotent!

  def perform(limit: 100)
    # Check active job postings that haven't been checked recently
    targets = JobPosting.where.not(status: 'archived')
                        .where(target_url: present_urls)
                        .order(Arel.sql('RANDOM()'))
                        .limit(limit)

    targets.each do |job|
      check_link(job)
    end
  end

  private

  def present_urls
    # Ensure we only check jobs with URLs
    JobPosting.where.not(target_url: [nil, '']).select(:target_url)
  end

  def check_link(job)
    response = Faraday.head(job.target_url) do |req|
      req.options.timeout = 5
      req.options.open_timeout = 2
    end

    if response.status == 404
      archive_job(job, 'Link returned 404 (Not Found)')
    elsif [301, 302].include?(response.status)
      # Follow redirect once to see if it leads to a 404 or "expired" page
      follow_up = Faraday.get(response.headers['location'])
      if follow_up.body.downcase.include?('job is no longer available') || follow_up.body.downcase.include?('position has been filled')
        archive_job(job,
                    'Job no longer available (Redirect signal)')
      end
    end
  rescue Faraday::Error => e
    # If the site is down or timing out, we don't archive immediately,
    # but we log the attempt.
    Rails.logger.warn "[LinkMonitor] Connection failed for Job #{job.id}: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "[LinkMonitor] Unexpected error for Job #{job.id}: #{e.message}"
  end

  def archive_job(job, reason)
    Rails.logger.info "[LinkMonitor] Archiving Job #{job.id}: #{reason}"
    job.update!(status: 'archived')

    # Log as a pipeline step
    job.pipeline_steps.create!(
      status: 'archived',
      note: "[SYSTEM_MONITOR] #{reason}"
    )
  end
end
