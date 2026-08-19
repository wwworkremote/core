# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DataFetchers" do
  before { ActiveJob::Base.queue_adapter = :test }

  describe "GET /data_fetchers" do
    it "lists every registered fetcher's status" do
      get data_fetchers_path
      expect(response).to be_successful
    end
  end

  describe "POST /data_fetchers/run" do
    it "sets a success notice and redirects when the fetcher runs successfully" do
      allow(DataAcquisitionManager).to receive(:run).with("adzuna", force: false).and_return(success: true)

      post run_data_fetchers_path, params: { slug: "adzuna" }

      expect(response).to redirect_to(data_fetchers_path)
      expect(flash[:notice]).to include("adzuna").and include("started successfully")
    end

    it "sets an alert when the fetcher reports failure" do
      allow(DataAcquisitionManager).to receive(:run).and_return(success: false, error: "rate limited")

      post run_data_fetchers_path, params: { slug: "adzuna" }

      expect(flash[:alert]).to include("rate limited")
    end

    it "parses force=true from the string param" do
      allow(DataAcquisitionManager).to receive(:run).and_return(success: true)

      post run_data_fetchers_path, params: { slug: "adzuna", force: "true" }

      expect(DataAcquisitionManager).to have_received(:run).with("adzuna", force: true)
    end

    it "sets a critical-error alert and does not raise when DataAcquisitionManager.run raises" do
      allow(DataAcquisitionManager).to receive(:run).and_raise(StandardError, "boom")

      post run_data_fetchers_path, params: { slug: "adzuna" }

      expect(flash[:alert]).to include("Critical error").and include("boom")
    end
  end

  describe "POST /data_fetchers/run_all_by_type" do
    it "triggers every fetcher of the given type" do
      allow(DataAcquisitionManager).to receive(:run).and_return(success: true)

      post run_all_by_type_data_fetchers_path, params: { type: "API" }

      expect(DataAcquisitionManager).to have_received(:run).with("adzuna", force: false)
      expect(DataAcquisitionManager).to have_received(:run).with("remotive", force: false)
      expect(DataAcquisitionManager).not_to have_received(:run).with("indeed", anything)
      expect(flash[:notice]).to include("API")
    end

    it "sets an alert and does not raise when a run call raises" do
      allow(DataAcquisitionManager).to receive(:run).and_raise(StandardError, "boom")

      post run_all_by_type_data_fetchers_path, params: { type: "API" }

      expect(flash[:alert]).to include("boom")
    end
  end

  describe "POST /data_fetchers/toggle_pause (TASK-69.1)" do
    it "creates the source paused when none exists yet, then unpauses on a second toggle" do
      expect {
        post toggle_pause_data_fetchers_path, params: { slug: "adzuna" }
      }.to change { JobBoards::Source.find_by(slug: "adzuna")&.ingestion_paused }.from(nil).to(true)

      expect(response).to redirect_to(data_fetchers_path)

      expect {
        post toggle_pause_data_fetchers_path, params: { slug: "adzuna" }
      }.to change { JobBoards::Source.find_by(slug: "adzuna").ingestion_paused }.from(true).to(false)
    end
  end

  describe "DataAcquisitionManager.run respecting ingestion_paused (TASK-69.1)" do
    it "blocks a normal run when the source is disabled, but force still goes through" do
      JobBoards::Source.find_or_create_by!(slug: "adzuna") { |s| s.name = "Adzuna" }
                       .update!(ingestion_paused: true)
      allow(DataAcquisitionManager).to receive(:dispatch).and_return(success: true)

      post run_data_fetchers_path, params: { slug: "adzuna" }
      expect(flash[:alert]).to include("Adzuna is disabled")

      post run_data_fetchers_path, params: { slug: "adzuna", force: true }
      expect(flash[:notice]).to include("started successfully")
    end
  end

  describe "POST /data_fetchers/audit" do
    it "enqueues the audit job and redirects" do
      expect { post audit_data_fetchers_path }.to have_enqueued_job(JobBoards::AuditJob)
      expect(response).to redirect_to(data_fetchers_path)
    end
  end

  describe "POST /data_fetchers/enrich" do
    it "enqueues the content enrichment job and redirects" do
      expect { post enrich_data_fetchers_path }.to have_enqueued_job(JobBoards::ContentEnrichmentJob)
      expect(response).to redirect_to(data_fetchers_path)
    end
  end
end
