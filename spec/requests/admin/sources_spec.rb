# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Sources" do
  let!(:source) { create(:job_boards_source) }

  describe "GET /admin/sources" do
    it "returns a success response" do
      get admin_sources_path
      expect(response).to be_successful
    end
  end

  describe "GET /admin/sources/:id" do
    it "returns a success response" do
      get admin_source_path(source)
      expect(response).to be_successful
    end
  end

  describe "POST /admin/sources/:id/toggle_ingestion (TASK-69.1)" do
    it "flips ingestion_paused and redirects back to the source" do
      expect {
        post toggle_ingestion_admin_source_path(source)
      }.to change { source.reload.ingestion_paused }.from(false).to(true)

      expect(response).to redirect_to(admin_source_path(source))
    end
  end

  describe "POST /admin/sources/:id/toggle_exclusion (TASK-69.1)" do
    it "flips excluded_from_results and redirects back to the source" do
      expect {
        post toggle_exclusion_admin_source_path(source)
      }.to change { source.reload.excluded_from_results }.from(false).to(true)

      expect(response).to redirect_to(admin_source_path(source))
    end
  end
end
