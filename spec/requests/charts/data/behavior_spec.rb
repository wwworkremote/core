# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Charts::Data::Behavior", type: :request do
  describe "GET /charts/data/behavior/visits" do
    it "returns JSON data for visits" do
      get charts_data_behavior_visits_path
      expect(response).to be_successful
    end
  end

  describe "GET /charts/data/behavior/events" do
    it "returns JSON data for events" do
      get charts_data_behavior_events_path
      expect(response).to be_successful
    end
  end

  describe "GET /charts/data/behavior/referrers" do
    it "returns JSON data for referrers" do
      get charts_data_behavior_referrers_path
      expect(response).to be_successful
    end
  end
end
