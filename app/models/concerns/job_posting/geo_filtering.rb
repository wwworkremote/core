# frozen_string_literal: true

# TASK-85: the US-only rule, in one place. Browse, triage, and matching all
# route through this scope instead of each growing its own WHERE clause.
# country_code IS NULL means "not yet geocoded," not "confirmed foreign" --
# 71% of the corpus predates GeocodingJob storing country_code, so treating
# nil as excluded would hide most of the real US postings along with the
# unknown ones. Documented default: known non-US is hidden, unknown stays
# visible until bin/backfill_country_codes narrows the unknown set down.
module JobPosting::GeoFiltering
  extend ActiveSupport::Concern

  included do
    scope :geo_allowed, -> { where(country_code: [nil, "US"]) }
  end
end
