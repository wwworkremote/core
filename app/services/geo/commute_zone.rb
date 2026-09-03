# frozen_string_literal: true

# Decides whether a non-remote job's location is within an acceptable
# commute zone: home-adjacent ("hyperlocal"), anywhere along the Metra
# UP-NW line (the line this filter targets), or downtown Chicago
# specifically within walking distance of Ogilvie or Union -- the two
# UP-NW terminals -- not the Loop generally, since the rest of downtown
# isn't reachable without a second transfer.
#
# Station/terminal coordinates are resolved through the same geocoder +
# cache as home, rather than hardcoded lat/lngs -- one fewer thing to keep
# in sync if a station's canonical address search result ever shifts.
#
# Configuration lives entirely in ENV, never in code -- HOME_LOCATION is
# personal address information and must never be committed. Set it in
# .env.local (gitignored), never in the tracked .env.
class Geo::CommuteZone
  DEFAULT_HYPERLOCAL_RADIUS_MILES = 10.0
  DEFAULT_STATION_RADIUS_MILES = 1.5
  DEFAULT_TERMINAL_WALK_RADIUS_MILES = 0.75

  # The two UP-NW downtown terminals -- a much tighter radius than the old
  # flat "Chicago Loop" circle, since the constraint is walking distance
  # from these two stations specifically, not the neighborhood generally.
  TERMINALS = [
    "Ogilvie Transportation Center, Chicago, IL",
    "Union Station, Chicago, IL"
  ].freeze

  # Every UP-NW stop from Ogilvie out to Harvard, IL (the end of the line),
  # minus the two terminals above. Minor stops omitted where they sit
  # within a station radius of an adjacent named stop already in this list
  # (Gladstone Park/Dee Road/Cumberland/Arlington Park/Pingree Road) --
  # station_radius covers them without one geocode call each.
  UP_NW_STATIONS = [
    "Clybourn, Chicago, IL",
    "Irving Park, Chicago, IL",
    "Jefferson Park, Chicago, IL",
    "Norwood Park, Chicago, IL",
    "Edison Park, Chicago, IL",
    "Park Ridge, IL",
    "Des Plaines, IL",
    "Mount Prospect, IL",
    "Arlington Heights, IL",
    "Palatine, IL",
    "Barrington, IL",
    "Fox River Grove, IL",
    "Cary, IL",
    "McHenry, IL",
    "Crystal Lake, IL",
    "Woodstock, IL",
    "Harvard, IL"
  ].freeze

  def self.call(job_posting)
    new(job_posting).call
  end

  # Memoized per-process, keyed by address -- home/loop coordinates don't
  # change between jobs, and this avoids a geocoding API call per posting.
  # Under a race, worst case is two threads geocoding the same address
  # once each -- not a correctness hazard, so ThreadSafety/
  # ClassInstanceVariable is disabled rather than adding synchronization
  # this doesn't need. Defined above `private` -- singleton methods
  # ignore that keyword, so keeping it visually separate avoids implying
  # a privacy this class can't actually enforce.
  # rubocop:disable-next ThreadSafety/ClassInstanceVariable
  def self.geocode(address)
    return nil if address.blank?

    @geocode_cache ||= {}
    return @geocode_cache[address] if @geocode_cache.key?(address)

    result = Geocoder.search(address).first
    @geocode_cache[address] = result ? [result.latitude, result.longitude] : nil
  end

  def initialize(job_posting)
    @job_posting = job_posting
  end

  # :allowed, :blocked, or :undetermined (job hasn't been geocoded yet --
  # absence of proof isn't proof of a bad commute, so callers should not
  # treat :undetermined the same as :blocked).
  def call
    return :allowed if remote?
    return :undetermined unless geocoded?

    within_zone? ? :allowed : :blocked
  end

  private

  # "remote" is the key JobPostingEnrichment::AttributeBuilder writes (every
  # extension capture/enrich and the standard scraper enrichment path);
  # "is_remote" is a separate key JobBoards::CategorizerAgent writes on its
  # own AI categorization pass. Checking only the latter (the original bug
  # here) meant a posting flagged remote by the primary pipeline, with no
  # literal "remote" in its free-text location, fell through to a real
  # distance check against home/Loop coordinates -- and could get silently
  # auto-ignored despite being remote. Check both; either is authoritative.
  def remote?
    @job_posting.data["remote"] == true || @job_posting.data["is_remote"] == true ||
      @job_posting.location.to_s.match?(/remote/i)
  end

  def geocoded?
    @job_posting.latitude.present? && @job_posting.longitude.present?
  end

  def within_zone?
    within_radius_of?(home_coords, hyperlocal_radius) ||
      near_any?(TERMINALS, terminal_radius) ||
      near_any?(UP_NW_STATIONS, station_radius)
  end

  def near_any?(addresses, radius_miles)
    addresses.any? { |address| within_radius_of?(self.class.geocode(address), radius_miles) }
  end

  def within_radius_of?(center, radius_miles)
    return false unless center

    Geocoder::Calculations.distance_between(job_coords, center, units: :mi) <= radius_miles
  end

  def job_coords
    [@job_posting.latitude, @job_posting.longitude]
  end

  def hyperlocal_radius
    ENV.fetch("HYPERLOCAL_RADIUS_MILES", DEFAULT_HYPERLOCAL_RADIUS_MILES).to_f
  end

  def station_radius
    ENV.fetch("STATION_RADIUS_MILES", DEFAULT_STATION_RADIUS_MILES).to_f
  end

  def terminal_radius
    ENV.fetch("TERMINAL_WALK_RADIUS_MILES", DEFAULT_TERMINAL_WALK_RADIUS_MILES).to_f
  end

  def home_coords
    self.class.geocode(ENV.fetch("HOME_LOCATION", nil))
  end
end
