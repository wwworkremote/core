# frozen_string_literal: true

module JobLifecycle
  class ExpirySweepJob < ApplicationJob
    queue_as :low
    mediumweight!

    def perform
      stale_postings = JobPosting.where("published_at < ?", 72.hours.ago)
                                 .where.not(status: "expired")

      Rails.logger.info "[ExpirySweep] Found #{stale_postings.count} stale postings to expire."

      stale_postings.find_each do |posting|
        # Skip if favorited or applied - user action should preserve them
        next if %w[favorited applied interview offered].include?(posting.status)

        posting.expire!
      end
    end
  end
end
