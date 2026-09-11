# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V0::Geo" do
  describe "GET /api/v0/geo" do
    it "geocodes the given ip param" do
      allow(GEOIP).to receive(:city).with("8.8.8.8").and_return({ city_name: "Mountain View" })

      get api_v0_geo_path, params: { ip: "8.8.8.8" }

      expect(response).to be_successful
      expect(response.parsed_body["geoip"]["city_name"]).to eq("Mountain View")
    end

    it "falls back to the request's remote_ip when no ip param is given" do
      allow(GEOIP).to receive(:city).and_return(nil)

      get api_v0_geo_path

      expect(response).to be_successful
      expect(GEOIP).to have_received(:city).with(request.remote_ip)
    end

    it "returns a bare ip payload when the lookup raises" do
      allow(GEOIP).to receive(:city).and_raise(StandardError, "boom")

      get api_v0_geo_path, params: { ip: "8.8.8.8" }

      expect(response).to be_successful
      expect(response.parsed_body["geoip"]["ip"]).to eq("8.8.8.8")
    end
  end
end
