# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Sources", type: :request do
  let!(:source) { create(:job_boards_source, name: "Test Source") }

  describe "GET /admin/sources" do
    it "returns a success response" do
      get admin_sources_path
      expect(response).to be_successful
      expect(response.body).to include("Test Source")
    end
  end

  describe "GET /admin/sources/:id" do
    it "returns a success response" do
      get admin_source_path(source)
      expect(response).to be_successful
      expect(response.body).to include("Test Source")
    end
  end
end
