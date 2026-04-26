# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Visits", type: :request do
  let!(:visit) { Ahoy::Visit.create!(started_at: Time.current) }

  describe "GET /admin/visits" do
    it "returns a success response" do
      get admin_visits_path
      expect(response).to be_successful
    end
  end

  describe "GET /admin/visits/:id" do
    it "returns a success response" do
      get admin_visit_path(visit)
      expect(response).to be_successful
    end
  end
end
