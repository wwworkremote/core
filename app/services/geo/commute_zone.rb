# frozen_string_literal: true

# Decides whether a non-remote job's location is within an acceptable
# commute zone -- home-adjacent ("hyper local") or the Chicago Loop.
# Distance-based rather than a hardcoded Metra station list: avoids
# needing an exact, possibly-wrong list of station names, and needs no
# maintenance as stations/lines change.
#
# Configuration lives entirely in ENV, never in code -- HOME_LOCATION is
# personal address information and must never be committed. Set it in
# .env.local (gitignored), never in the tracked .env.
class Geo::CommuteZone
  DEFAULT_HYPERLOCAL_RADIUS_MILES = 10.0
  DEFAULT_CHICAGO_LOOP_RADIUS_MILES = 2.0
  CHICAGO_LOOP_LOCATION = "Chicago Loop, Chicago, IL"

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
  # rubocop:disable ThreadSafety/ClassInstanceVariable
  def self.geocode(address)
    return nil if address.blank?

    @geocode_cache ||= {}
    return @geocode_cache[address] if @geocode_cache.key?(address)

    result = Geocoder.search(address).first
    @geocode_cache[address] = result ? [result.latitude, result.longitude] : nil
  end
  # rubocop:enable ThreadSafety/ClassInstanceVariable

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
    within_radius_of?(home_coords, hyperlocal_radius) || within_radius_of?(loop_coords, loop_radius)
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

  def loop_radius
    ENV.fetch("CHICAGO_LOOP_RADIUS_MILES", DEFAULT_CHICAGO_LOOP_RADIUS_MILES).to_f
  end

  def home_coords
    self.class.geocode(ENV.fetch("HOME_LOCATION", nil))
  end

  def loop_coords
    self.class.geocode(CHICAGO_LOOP_LOCATION)
  end
end
