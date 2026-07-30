# frozen_string_literal: true

class JobLifecycle::ExpirySweepJob < ApplicationJob
  queue_as :low
  mediumweight!

  PRESERVED_STATUSES = %w[favorited applied interview offered].freeze

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

  # Skip if favorited or applied - user action should preserve them
  def expire_if_eligible(posting)
    return if PRESERVED_STATUSES.include?(posting.status)

    posting.expire!
  end
end
