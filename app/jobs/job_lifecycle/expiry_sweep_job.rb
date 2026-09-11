# frozen_string_literal: true

class JobLifecycle::ExpirySweepJob < ApplicationJob
  queue_as :low
  mediumweight!

  def perform
    Rails.logger.info "[ExpirySweep] Found #{stale_postings.count} stale postings to expire."
    stale_postings.find_each { |posting| expire_if_eligible(posting) }
  end

  private

  # expire (AASM) only transitions from none/favorited/archived/ignored -- purged
  # (and applied/interview/offered, already skipped below) raise
  # AASM::InvalidTransition and halt the whole find_each batch mid-sweep.
  def stale_postings
    JobPosting.where(published_at: ...72.hours.ago)
              .where.not(status: %w[expired purged])
  end

  # Pipeline stage/outcome live entirely on UserJobPosting as of TASK-82
  # phase 3 -- checking JobPosting.status against favorited/applied/etc
  # (the pre-phase-3 shape) would never match anything anymore and silently
  # expire postings Mike is actively pursuing. Preserve if any user has
  # active pipeline involvement (UserJobPosting::ACTIVE_STATUSES) or an
  # offer recorded.
  def expire_if_eligible(posting)
    return if active_pipeline?(posting)

    posting.expire!
  end

  def active_pipeline?(posting)
    posting.user_job_postings.exists?(["status IN (?) OR outcome = ?", UserJobPosting::ACTIVE_STATUSES, "offered"])
  end
end
