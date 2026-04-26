# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Events", type: :request do
  let!(:visit) { Ahoy::Visit.create!(started_at: Time.current) }
  let!(:event) { Ahoy::Event.create!(visit: visit, name: "Test Event", time: Time.current) }

  describe "GET /admin/events" do
    it "returns a success response" do
      get admin_events_path
      expect(response).to be_successful
    end
  end

  describe "GET /admin/events/:id" do
    it "returns a success response" do
      get admin_event_path(event)
      expect(response).to be_successful
    end
  end
end
