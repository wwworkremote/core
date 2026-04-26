# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Observability", type: :request do
  describe "GET /admin/observability" do
    it "returns a success response" do
      get admin_observability_path
      expect(response).to be_successful
      expect(response.body).to include("Observability")
    end
  end
end
