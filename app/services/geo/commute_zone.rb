# frozen_string_literal: true

# Decides whether a non-remote job's location is within an acceptable
# commute zone. The zone is entirely data-driven: a home point with a
# radius, plus any number of named "zones" -- a zone is a set of places
# and a radius, and a job within that radius of ANY place in the zone
# counts as an acceptable commute. A rail line is just a zone whose places
# are its stations; a walkable downtown is a zone with a tight radius.
#
# Config lives in `config/commute_zone.yml` (gitignored -- it carries
# location information). No file, or an empty one, means the filter is
# inert: it never blocks a geocoded posting. See `commute_zone.yml.example`
# for the shape. `home:` may also be left in `ENV["HOME_LOCATION"]`.
#
# Place coordinates are resolved through the app Geocoder + a per-process
# cache, not hardcoded lat/lngs.
#
# rubocop:disable ThreadSafety/ClassInstanceVariable -- @config / @geocode_cache
# are per-process read-through caches of immutable config; a race just repeats a
# harmless read. See the note on .geocode.
class Geo::CommuteZone
  DEFAULT_HOME_RADIUS_MILES = 10.0
  CONFIG_PATH = Rails.root.join("config/commute_zone.yml")

  Zone = Data.define(:name, :radius_miles, :places)

  class << self
    def call(job_posting)
      new(job_posting).call
    end

    def config
      @config ||= CONFIG_PATH.exist? ? (YAML.safe_load_file(CONFIG_PATH) || {}) : {}
    end

    def reload_config!
      @config = nil
      @geocode_cache = nil
    end

    def home_location
      config["home"].presence || ENV.fetch("HOME_LOCATION", nil)
    end

    def home_radius_miles
      (config["home_radius_miles"] || DEFAULT_HOME_RADIUS_MILES).to_f
    end

    def zones
      Array(config["zones"]).map { |zone| build_zone(zone) }
    end

    # Nothing to check against -- callers should treat every geocoded
    # posting as :allowed rather than purging the corpus.
    def configured?
      home_location.present? || zones.any?
    end

    # Memoized per-process, keyed by address -- zone coordinates don't
    # change between jobs, and this avoids a geocoding API call per
    # posting. Under a race, worst case is two threads geocoding the same
    # address once each -- not a correctness hazard.
    def geocode(address)
      return nil if address.blank?

      @geocode_cache ||= {}
      return @geocode_cache[address] if @geocode_cache.key?(address)

      result = Geocoder.search(address).first
      @geocode_cache[address] = result ? [result.latitude, result.longitude] : nil
    end

    private

    def build_zone(zone)
      Zone.new(name: zone["name"], radius_miles: zone["radius_miles"].to_f, places: Array(zone["places"]))
    end
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
  # own AI categorization pass. Check both; either is authoritative.
  def remote?
    @job_posting.data["remote"] == true || @job_posting.data["is_remote"] == true ||
      @job_posting.location.to_s.match?(/remote/i)
  end

  def geocoded?
    @job_posting.latitude.present? && @job_posting.longitude.present?
  end

  def within_zone?
    return true unless self.class.configured?

    near_home? || self.class.zones.any? { |zone| in_zone?(zone) }
  end

  def near_home?
    near?(self.class.home_location, self.class.home_radius_miles)
  end

  def in_zone?(zone)
    zone.places.any? { |place| near?(place, zone.radius_miles) }
  end

  def near?(address, radius_miles)
    center = self.class.geocode(address)
    return false unless center

    Geocoder::Calculations.distance_between(job_coords, center, units: :mi) <= radius_miles
  end

  def job_coords
    [@job_posting.latitude, @job_posting.longitude]
  end
end
# rubocop:enable ThreadSafety/ClassInstanceVariable
