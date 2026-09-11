# frozen_string_literal: true

# Query-time location/remote filtering for the browse UI
# (JobPostingsController#index) -- distinct from Geo::CommuteZone, which
# proactively auto-ignores postings outside the configured commute zone.
# remote_only mirrors Geo::CommuteZone#remote? exactly (same two structured
# data keys plus the free-text fallback) so "browse as remote" and
# "auto-ignore for commute" always agree on what counts as remote.
module JobPosting::LocationFiltering
  extend ActiveSupport::Concern

  included do
    scope :location_matches, ->(text) { where("location ILIKE ?", "%#{sanitize_sql_like(text)}%") }
    scope :remote_only, lambda {
      where("data->>'remote' = 'true' OR data->>'is_remote' = 'true' OR location ILIKE '%remote%'")
    }
  end
end
