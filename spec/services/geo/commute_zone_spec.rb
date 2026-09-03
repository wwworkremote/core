# frozen_string_literal: true

require "rails_helper"

RSpec.describe Geo::CommuteZone do
  # Synthetic fixtures — coordinates only need to be self-consistent with the
  # distances asserted below, not geographically real.
  let(:home_stub) { { "latitude" => 40.00, "longitude" => -80.00 } }
  let(:anchor_stub) { { "latitude" => 41.00, "longitude" => -81.00 } }
  let(:line_stop_stub) { { "latitude" => 40.30, "longitude" => -80.20 } }

  let(:test_config) do
    {
      "home" => "Test Home",
      "home_radius_miles" => 10.0,
      "zones" => [
        { "name" => "Rail line", "radius_miles" => 1.5, "places" => ["Line Stop"] },
        { "name" => "Downtown anchor", "radius_miles" => 0.75, "places" => ["City Anchor"] }
      ]
    }
  end

  around do |example|
    described_class.instance_variable_set(:@config, test_config)
    described_class.instance_variable_set(:@geocode_cache, nil)
    Geocoder::Lookup::Test.set_default_stub([]) # anything not stubbed: "not found"
    Geocoder::Lookup::Test.add_stub("Test Home", [home_stub])
    Geocoder::Lookup::Test.add_stub("Line Stop", [line_stop_stub])
    Geocoder::Lookup::Test.add_stub("City Anchor", [anchor_stub])

    example.run

    described_class.reload_config!
  end

  def job_posting_at(lat, lng, location: "Somewhere", data: {})
    build_stubbed(:job_posting, location: location, latitude: lat, longitude: lng, data: data)
  end

  describe ".call" do
    it "allows a posting whose location text says remote, without coordinates" do
      expect(described_class.call(job_posting_at(nil, nil, location: "Remote - USA"))).to eq(:allowed)
    end

    it "allows a posting the categorizer flagged remote (is_remote key)" do
      expect(described_class.call(job_posting_at(nil, nil, data: { "is_remote" => true }))).to eq(:allowed)
    end

    it "allows a posting the primary enrichment pipeline flagged remote (remote key)" do
      posting = job_posting_at(nil, nil, location: "Hockenheim", data: { "remote" => true })
      expect(described_class.call(posting)).to eq(:allowed)
    end

    it "is undetermined for a non-remote posting that hasn't been geocoded yet" do
      expect(described_class.call(job_posting_at(nil, nil))).to eq(:undetermined)
    end

    it "allows a geocoded posting within the home radius" do
      expect(described_class.call(job_posting_at(40.05, -80.05))).to eq(:allowed)
    end

    it "allows a geocoded posting within a zone place's radius" do
      expect(described_class.call(job_posting_at(40.301, -80.201))).to eq(:allowed)
    end

    it "blocks a geocoded posting far from home and every zone place" do
      expect(described_class.call(job_posting_at(34.0522, -118.2437))).to eq(:blocked) # Los Angeles
    end

    it "falls back to ENV['HOME_LOCATION'] when the config has no home" do
      described_class.instance_variable_set(:@config, test_config.except("home"))
      ENV["HOME_LOCATION"] = "Test Home"

      expect(described_class.call(job_posting_at(40.05, -80.05))).to eq(:allowed)
    ensure
      ENV.delete("HOME_LOCATION")
    end
  end

  describe ".call when nothing is configured" do
    around do |example|
      described_class.instance_variable_set(:@config, {})
      original_home = ENV.delete("HOME_LOCATION")
      example.run
      ENV["HOME_LOCATION"] = original_home if original_home
      described_class.reload_config!
    end

    it "is inert — a geocoded posting anywhere is allowed, not blocked" do
      expect(described_class.configured?).to be(false)
      expect(described_class.call(job_posting_at(34.0522, -118.2437))).to eq(:allowed)
    end
  end

  describe ".zones" do
    it "reads the named zones and radii from config" do
      expect(described_class.zones.map(&:name)).to eq(["Rail line", "Downtown anchor"])
      expect(described_class.zones.first).to have_attributes(radius_miles: 1.5, places: ["Line Stop"])
    end
  end
end
