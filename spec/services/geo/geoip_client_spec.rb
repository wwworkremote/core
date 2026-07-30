# frozen_string_literal: true

require "rails_helper"

RSpec.describe Geo::GeoipClient do
  describe ".build" do
    it "returns a NullClient if the database file is missing" do
      allow(File).to receive(:exist?).and_return(false)
      client = described_class.build
      expect(client).to be_a(Geo::GeoipClient::NullClient)
      expect(client.city("8.8.8.8")).to be_nil
    end

    it "initializes correctly if database exists" do
      allow(File).to receive(:exist?).and_return(true)
      mock_reader = instance_double(MaxMind::GeoIP2::Reader)
      allow(MaxMind::GeoIP2::Reader).to receive(:new).and_return(mock_reader)

      client = described_class.build
      expect(client).to be_a(described_class)
    end

    it "returns a NullClient and logs when initialization raises" do
      allow(File).to receive(:exist?).and_return(true)
      allow(MaxMind::GeoIP2::Reader).to receive(:new).and_raise(StandardError.new("boom"))
      logger = instance_double(Logger, error: nil)

      client = described_class.build(logger: logger)

      expect(client).to be_a(Geo::GeoipClient::NullClient)
      expect(logger).to have_received(:error).with(/Failed to initialize: boom/)
    end
  end

  describe "#city" do
    let(:mock_reader) { instance_double(MaxMind::GeoIP2::Reader) }
    let(:client) { described_class.new(reader: mock_reader) }

    it "extracts data from MaxMind result" do
      mock_result = double(
        city: double(name: "Chicago"),
        country: double(iso_code: "US"),
        postal: double(code: "60601"),
        location: double(latitude: 41.8, longitude: -87.6, time_zone: "America/Chicago"),
        subdivisions: [double(iso_code: "IL")]
      )
      allow(mock_reader).to receive(:city).with("1.1.1.1").and_return(mock_result)

      res = client.city("1.1.1.1")
      expect(res[:city]).to eq("Chicago")
      expect(res[:region]).to eq("IL")
      expect(res[:country]).to eq("US")
    end

    it "handles AddressNotFoundError" do
      allow(mock_reader).to receive(:city).and_raise(MaxMind::GeoIP2::AddressNotFoundError.new("Not found"))
      expect(client.city("0.0.0.0")).to be_nil
    end

    it "logs and returns nil on unexpected errors" do
      allow(mock_reader).to receive(:city).and_raise(StandardError.new("connection reset"))
      allow(Rails.logger).to receive(:error)

      expect(client.city("2.2.2.2")).to be_nil
      expect(Rails.logger).to have_received(:error).with(/Lookup error for 2.2.2.2: connection reset/)
    end
  end
end
