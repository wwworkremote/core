# frozen_string_literal: true

# Geocodes JobPosting#location and enforces the user's configured commute
# zone (Geo::CommuteZone) once coordinates land -- split out of the main
# model since it's a self-contained cross-cutting concern, not core
# JobPosting behavior.
module JobPosting::Geocoding
  extend ActiveSupport::Concern

  included do
    geocoded_by :location
    after_commit :enqueue_geocoding, on: %i[create update], if: lambda {
      location.present? && (saved_change_to_location? || latitude.nil?)
    }
    # Geocoding is async (GeocodingJob), so this is the earliest point a
    # non-remote posting's commute feasibility is actually knowable.
    after_commit :enforce_commute_zone, on: :update, if: -> { saved_change_to_latitude? || saved_change_to_longitude? }
  end

  class_methods do
    def geocode_all
      where(latitude: nil, longitude: nil).where.not(location: nil).find_each do |posting|
        JobBoards::GeocodingJob.perform_later(posting.id)
      end
    end
  end

  def enqueue_geocoding
    JobBoards::GeocodingJob.perform_later(id)
  end

  # TASK-82 (#2125): a posting geocoded (or re-geocoded) after Mike already
  # favorited/applied/etc. would otherwise get silently auto-ignored out
  # from under him, with no PipelineStep recording why JobPosting.status
  # and his real activity stopped agreeing. Geo-blocking should only ever
  # apply before he's touched a posting, never override that he did.
  def enforce_commute_zone
    return unless may_ignore?
    return if user_job_postings.where.not(status: [nil, "none"]).exists?

    ignore! if Geo::CommuteZone.call(self) == :blocked
  end
end
