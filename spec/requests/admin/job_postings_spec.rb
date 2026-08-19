# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::JobPostings" do
  let!(:job_posting) { create(:job_posting) }

  describe "GET /admin/job_postings" do
    it "lists non-purged job postings by default" do
      purged = create(:job_posting, title: "Purged Engineer", status: "purged")

      get admin_job_postings_path

      expect(response).to be_successful
      expect(response.body).to include(job_posting.title)
      expect(response.body).not_to include(purged.title)
    end

    it "lists purged job postings when status=purged" do
      job_posting.purge!

      get admin_job_postings_path(status: "purged")

      expect(response).to be_successful
      expect(response.body).to include(job_posting.title)
    end
  end

  describe "GET /admin/job_postings/:id" do
    it "redirects to the unified job posting page" do
      get admin_job_posting_path(job_posting)
      expect(response).to redirect_to(job_posting_path(job_posting))
    end

    it "renders the semantic matches partial when framed" do
      get admin_job_posting_path(job_posting, frame: "semantic_matches")
      expect(response).to be_successful
    end
  end

  describe "PATCH /admin/job_postings/:id" do
    it "triggers enrichment and redirects" do
      allow(Scraper::Enricher).to receive(:call)

      patch admin_job_posting_path(job_posting), params: { action_type: "enrich" }

      expect(Scraper::Enricher).to have_received(:call).with(job_posting)
      expect(response).to redirect_to(job_posting_path(job_posting))
      expect(flash[:notice]).to eq("Enrichment complete.")
    end

    it "triggers synthesis (categorization) forced, and redirects" do
      categorizer = instance_double(JobBoards::Categorizer, call: true)
      allow(JobBoards::Categorizer).to receive(:new).with(job_posting).and_return(categorizer)

      patch admin_job_posting_path(job_posting), params: { action_type: "synthesize" }

      expect(categorizer).to have_received(:call).with(force: true)
      expect(flash[:notice]).to eq("Synthesis triggered.")
    end

    it "redirects without a notice for an unknown action_type" do
      patch admin_job_posting_path(job_posting), params: { action_type: "bogus" }

      expect(response).to redirect_to(job_posting_path(job_posting))
      expect(flash[:notice]).to be_nil
    end
  end

  describe "POST /admin/job_postings/:id/purge" do
    it "purges the job posting and redirects" do
      post purge_admin_job_posting_path(job_posting)

      expect(job_posting.reload.status).to eq("purged")
      expect(response).to redirect_to(admin_job_postings_path)
    end
  end

  describe "POST /admin/job_postings/:id/restore" do
    it "restores a purged job posting and redirects" do
      job_posting.purge!

      post restore_admin_job_posting_path(job_posting)

      expect(job_posting.reload.status).to eq("none")
    end
  end

  describe "DELETE /admin/job_postings/:id (TASK-69.4)" do
    it "permanently deletes the job posting and redirects to the admin index" do
      expect {
        delete admin_job_posting_path(job_posting)
      }.to change(JobPosting, :count).by(-1)

      expect(response).to redirect_to(admin_job_postings_path)
      expect(flash[:notice]).to eq("Job posting was permanently deleted.")
    end
  end

  describe "POST /admin/job_postings/bulk_action" do
    it "purges the selected records" do
      post bulk_action_admin_job_postings_path, params: { job_ids: [job_posting.id], bulk_operation: "purge" }

      expect(job_posting.reload.status).to eq("purged")
      expect(flash[:notice]).to eq("1 records moved to trash.")
    end

    it "restores the selected records" do
      job_posting.purge!

      post bulk_action_admin_job_postings_path, params: { job_ids: [job_posting.id], bulk_operation: "restore" }

      expect(job_posting.reload.status).to eq("none")
      expect(flash[:notice]).to eq("1 records restored.")
    end

    it "permanently deletes the selected records" do
      expect {
        post bulk_action_admin_job_postings_path, params: { job_ids: [job_posting.id], bulk_operation: "delete" }
      }.to change(JobPosting, :count).by(-1)

      expect(flash[:notice]).to eq("1 records permanently deleted.")
    end

    it "notices no records selected when job_ids is blank" do
      post bulk_action_admin_job_postings_path, params: { bulk_operation: "purge" }
      expect(flash[:notice]).to eq("No records selected.")
    end
  end

  describe "DELETE /admin/job_postings/:id" do
    it "permanently deletes the job posting and redirects" do
      expect { delete admin_job_posting_path(job_posting) }.to change(JobPosting, :count).by(-1)
      expect(response).to redirect_to(admin_job_postings_path)
    end
  end
end
