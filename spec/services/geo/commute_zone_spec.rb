# frozen_string_literal: true

require "rails_helper"

RSpec.describe Geo::CommuteZone do
  # Home: an arbitrary point NW of the terminal. Ogilvie: roughly its real
  # downtown coordinates. Cary: a UP-NW station roughly on-line but a
  # few towns further from home. Coordinates only
  # need to be self-consistent with the test distances below, not
  # geographically exact.
  let(:home_stub) { { "latitude" => 42.30, "longitude" => -88.40 } }
  let(:ogilvie_stub) { { "latitude" => 41.8839, "longitude" => -87.6408 } }
  let(:cary_stub) { { "latitude" => 42.2114, "longitude" => -88.2384 } }

  around do |example|
    original_home = ENV.fetch("HOME_LOCATION", nil)
    ENV["HOME_LOCATION"] = "[home location]"
    described_class.instance_variable_set(:@geocode_cache, nil)
    Geocoder::Lookup::Test.set_default_stub([]) # every other UP-NW station/terminal: "not found"
    Geocoder::Lookup::Test.add_stub("[home location]", [home_stub])
    Geocoder::Lookup::Test.add_stub("Ogilvie Transportation Center, Chicago, IL", [ogilvie_stub])
    Geocoder::Lookup::Test.add_stub("Cary, IL", [cary_stub])

    example.run

    ENV["HOME_LOCATION"] = original_home
    described_class.instance_variable_set(:@geocode_cache, nil)
  end

  def job_posting_at(lat, lng, location: "Somewhere, IL", data: {})
    build_stubbed(:job_posting, location: location, latitude: lat, longitude: lng, data: data)
  end

  describe ".call" do
    it "allows postings whose location text says remote, without needing coordinates" do
      posting = job_posting_at(nil, nil, location: "Remote - USA")

      expect(described_class.call(posting)).to eq(:allowed)
    end

    it "allows postings the categorizer already flagged as remote (is_remote key)" do
      posting = job_posting_at(nil, nil, data: { "is_remote" => true })

      expect(described_class.call(posting)).to eq(:allowed)
    end

    it "allows postings the primary enrichment pipeline flagged as remote (remote key)" do
      # Regression: AttributeBuilder writes data["remote"], not
      # data["is_remote"] -- this is the key every extension capture and
      # standard scraper enrichment actually sets. Location text
      # deliberately has no "remote" mention so only the structured flag
      # can be doing the work here.
      posting = job_posting_at(nil, nil, location: "Hockenheim", data: { "remote" => true })

      expect(described_class.call(posting)).to eq(:allowed)
    end

    it "is undetermined for a non-remote posting that hasn't been geocoded yet" do
      posting = job_posting_at(nil, nil)

      expect(described_class.call(posting)).to eq(:undetermined)
    end

    it "allows a geocoded posting within the hyperlocal radius of home" do
      posting = job_posting_at(42.25, -88.30) # a few miles from the home stub

      expect(described_class.call(posting)).to eq(:allowed)
    end

    it "allows a geocoded posting within walking distance of Ogilvie" do
      posting = job_posting_at(41.884, -87.641) # right by the Ogilvie stub

      expect(described_class.call(posting)).to eq(:allowed)
    end

    it "allows a geocoded posting near a UP-NW line station away from home" do
      posting = job_posting_at(42.211, -88.238) # right by the Cary stub

      expect(described_class.call(posting)).to eq(:allowed)
    end

    it "blocks a geocoded posting far from home, every UP-NW station, and both terminals" do
      posting = job_posting_at(34.0522, -118.2437) # Los Angeles

      expect(described_class.call(posting)).to eq(:blocked)
    end

    it "still allows an Ogilvie-adjacent posting when HOME_LOCATION is unset" do
      ENV["HOME_LOCATION"] = nil
      posting = job_posting_at(41.884, -87.641)

      expect(described_class.call(posting)).to eq(:allowed)
    end

    it "can no longer apply the hyperlocal exception when HOME_LOCATION is unset" do
      ENV["HOME_LOCATION"] = nil
      posting = job_posting_at(42.25, -88.30) # would be hyperlocal-allowed if home were configured

      expect(described_class.call(posting)).to eq(:blocked)
    end
  end
end
