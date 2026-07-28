# frozen_string_literal: true

class JobLifecycle::ExpirySweepJob < ApplicationJob
  queue_as :low
  mediumweight!

  def perform
    # expire (AASM) only transitions from none/favorited/archived/ignored -- purged
    # (and applied/interview/offered, already skipped below) raise
    # AASM::InvalidTransition and halt the whole find_each batch mid-sweep.
    stale_postings = JobPosting.where(published_at: ...72.hours.ago)
                               .where.not(status: %w[expired purged])

    Rails.logger.info "[ExpirySweep] Found #{stale_postings.count} stale postings to expire."

    stale_postings.find_each do |posting|
      # Skip if favorited or applied - user action should preserve them
      next if %w[favorited applied interview offered].include?(posting.status)

      posting.expire!
    end
  end
end
