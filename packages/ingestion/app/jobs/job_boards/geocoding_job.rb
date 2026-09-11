# frozen_string_literal: true

class JobBoards::GeocodingJob < ApplicationJob
  include ApiGuard

  queue_as :light
  lightweight!
  idempotent! ->(id) { "geocoding/#{id}" }

  def perform(job_posting_id, force: false)
    return if source_locked?("geocoding")

    job_posting = JobPosting.find_by(id: job_posting_id)
    return unless geocodable?(job_posting, force)

    geocode(job_posting)
  end

  private

  def geocodable?(job_posting, force)
    return false unless job_posting && job_posting.location.present?

    # Shield: Do not process geocoding for expired/stale jobs unless forced
    !(job_posting.expired? && !force)
  end

  def geocode(job_posting)
    attempt_geocode(job_posting)
  rescue Geocoder::OverQueryLimitError, Geocoder::RequestDenied
    lock_source!("geocoding", duration: 1.hour)
  rescue StandardError => e
    handle_geocode_error(job_posting.id, e)
  end

  def attempt_geocode(job_posting)
    result = Geocoder.search(job_posting.location).first
    apply_result(job_posting, result) if result
  end

  def apply_result(job_posting, result)
    job_posting.update!(geocode_attributes(result))
    log_success(job_posting, result)
  end

  def geocode_attributes(result)
    { latitude: result.latitude, longitude: result.longitude, country_code: result.country_code&.upcase }
  end

  def log_success(job_posting, result)
    Rails.logger.info "[GeocodingJob] Successfully geocoded Job #{job_posting.id}: " \
                      "#{job_posting.location} (#{result.country_code})"
  end

  def handle_geocode_error(job_posting_id, error)
    if error.message.include?("429")
      lock_source!("geocoding", duration: 1.hour)
    else
      Rails.logger.error "[GeocodingJob] Error geocoding Job #{job_posting_id}: #{error.message}"
    end
  end
end
