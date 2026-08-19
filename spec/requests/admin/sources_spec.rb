# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Sources" do
  before { ActiveJob::Base.queue_adapter = :test }

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

    it "enqueues an audit sweep when turning exclusion on, to catch already-ingested postings (TASK-69.2)" do
      expect {
        post toggle_exclusion_admin_source_path(source)
      }.to have_enqueued_job(JobBoards::AuditJob)
    end

    it "does not enqueue a sweep when turning exclusion back off" do
      source.update!(excluded_from_results: true)

      expect {
        post toggle_exclusion_admin_source_path(source)
      }.not_to have_enqueued_job(JobBoards::AuditJob)
    end
  end
end
