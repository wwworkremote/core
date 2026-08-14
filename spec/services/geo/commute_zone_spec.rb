# frozen_string_literal: true

require "rails_helper"

RSpec.describe Geo::CommuteZone do
  # Home: an arbitrary point NW of the terminal. Loop: roughly the Willis
  # Tower area. Coordinates only need to be self-consistent with the test
  # distances below, not geographically exact.
  let(:home_stub) { { "latitude" => 42.30, "longitude" => -88.40 } }
  let(:loop_stub) { { "latitude" => 41.8789, "longitude" => -87.6359 } }

  around do |example|
    original_home = ENV.fetch("HOME_LOCATION", nil)
    ENV["HOME_LOCATION"] = "[home location]"
    described_class.instance_variable_set(:@geocode_cache, nil)
    Geocoder::Lookup::Test.add_stub("[home location]", [home_stub])
    Geocoder::Lookup::Test.add_stub(described_class::CHICAGO_LOOP_LOCATION, [loop_stub])

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

    it "allows a geocoded posting within the Chicago Loop radius" do
      posting = job_posting_at(41.88, -87.63) # right by the loop stub

      expect(described_class.call(posting)).to eq(:allowed)
    end

    it "blocks a geocoded posting far from both home and the Loop" do
      posting = job_posting_at(34.0522, -118.2437) # Los Angeles

      expect(described_class.call(posting)).to eq(:blocked)
    end

    it "still allows the Loop zone independently when HOME_LOCATION is unset" do
      ENV["HOME_LOCATION"] = nil
      posting = job_posting_at(41.88, -87.63)

      expect(described_class.call(posting)).to eq(:allowed)
    end

    it "can no longer apply the hyperlocal exception when HOME_LOCATION is unset" do
      ENV["HOME_LOCATION"] = nil
      posting = job_posting_at(42.25, -88.30) # would be hyperlocal-allowed if home were configured

      expect(described_class.call(posting)).to eq(:blocked)
    end
  end
end
