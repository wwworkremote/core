# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Observability", type: :request do
  describe "GET /admin/observability" do
    it "returns a success response and renders signals" do
      create(:job_posting, enriched_at: Time.current, created_at: 10.minutes.ago)
      create(:source)
      
      get admin_observability_path
      expect(response).to be_successful
      expect(response.body).to include("Golden Signals")
    end
  end
end
