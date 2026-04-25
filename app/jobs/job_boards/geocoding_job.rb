# frozen_string_literal: true

module JobBoards
  class GeocodingJob < ApplicationJob
    include ApiGuard

    queue_as :light
    lightweight!
    idempotent! ->(id) { "geocoding/#{id}" }

    def perform(job_posting_id)
      return if source_locked?('geocoding')

      job_posting = JobPosting.find_by(id: job_posting_id)
      return unless job_posting && job_posting.location.present?

      begin
        # Geocoder.search returns an array of Geocoder::Result objects
        results = Geocoder.search(job_posting.location)

        if results.present?
          result = results.first
          job_posting.update!(
            latitude: result.latitude,
            longitude: result.longitude,
            country_code: result.country_code&.upcase
          )
          Rails.logger.info "[GeocodingJob] Successfully geocoded Job #{job_posting_id}: #{job_posting.location} (#{result.country_code})"
        end
      rescue Geocoder::OverQueryLimitError, Geocoder::RequestDenied
        lock_source!('geocoding', duration: 1.hour)
      rescue StandardError => e
        if e.message.include?('429')
          lock_source!('geocoding', duration: 1.hour)
        else
          Rails.logger.error "[GeocodingJob] Error geocoding Job #{job_posting_id}: #{e.message}"
        end
      end
    end
  end
end
