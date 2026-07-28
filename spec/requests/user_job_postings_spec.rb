# frozen_string_literal: true

require "rails_helper"

RSpec.describe "UserJobPostings" do
  let(:user) do
    User.find_or_create_by!(email: ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com")) do |u|
      u.name = ENV.fetch("ADMIN_NAME", "mike")
      u.password = ENV.fetch("ADMIN_PASSWORD", "password")
    end
  end
  let!(:job_posting) { create(:job_posting) }

  describe "POST /user_job_postings" do
    it "creates a UserJobPosting and redirects" do
      expect {
        post user_job_postings_path, params: { job_posting_id: job_posting.id }
      }.to change(UserJobPosting, :count).by(1)

      expect(response).to redirect_to(job_posting_path(job_posting))
      expect(flash[:notice]).to eq("Job status updated.")
    end

    it "applies an allowed AASM status event and logs a pipeline step" do
      expect {
        post user_job_postings_path, params: { job_posting_id: job_posting.id, status: "favorite" }
      }.to change(user.pipeline_steps, :count).by(1)

      expect(UserJobPosting.last.status).to eq("favorited")
      expect(user.pipeline_steps.last.note).to eq("User marked as favorite")
    end

    it "ignores a status event that is not in the allowed whitelist" do
      post user_job_postings_path, params: { job_posting_id: job_posting.id, status: "delete_everything" }

      expect(UserJobPosting.last.status).to eq("none")
    end

    it "sets job_search_id when provided" do
      job_search = user.job_searches.create!(name: "Remote Ruby roles")

      post user_job_postings_path, params: { job_posting_id: job_posting.id, job_search_id: job_search.id }

      expect(UserJobPosting.last.job_search_id).to eq(job_search.id)
    end
  end

  describe "PATCH /user_job_postings/:id" do
    it "updates and redirects" do
      ujp = user.user_job_postings.create!(job_posting: job_posting)

      patch user_job_posting_path(ujp), params: { user_job_posting: { notes: "Great fit" } }

      expect(ujp.reload.notes).to eq("Great fit")
      expect(response).to redirect_to(user_job_postings_path)
    end
  end

  describe "DELETE /user_job_postings/:id" do
    it "destroys and redirects" do
      ujp = user.user_job_postings.create!(job_posting: job_posting)

      expect { delete user_job_posting_path(ujp) }.to change(UserJobPosting, :count).by(-1)
      expect(response).to redirect_to(user_job_postings_path)
    end
  end

  describe "POST /user_job_postings/analyze_match" do
    it "flashes success and redirects when the scan succeeds" do
      allow(LLM::ProfileMatcher).to receive(:call).and_return(success: true)

      post analyze_match_user_job_postings_path, params: { job_posting_id: job_posting.id }

      expect(LLM::ProfileMatcher).to have_received(:call).with(user, job_posting, force: false)
      expect(flash[:notice]).to eq("AI alignment scan complete.")
      expect(response).to redirect_to(job_posting_path(job_posting))
    end

    it "flashes the error and passes force: true through when requested" do
      allow(LLM::ProfileMatcher).to receive(:call).and_return(success: false, error: "boom")

      post analyze_match_user_job_postings_path, params: { job_posting_id: job_posting.id, force: "true" }

      expect(LLM::ProfileMatcher).to have_received(:call).with(user, job_posting, force: true)
      expect(flash[:alert]).to eq("Scan failed: boom")
    end
  end

  describe "POST /user_job_postings/generate_artifacts" do
    it "flashes success and redirects when generation succeeds" do
      allow(LLM::ArtifactGenerator).to receive(:call).and_return(success: true)

      post generate_artifacts_user_job_postings_path, params: { job_posting_id: job_posting.id }

      expect(flash[:notice]).to eq("Bespoke application artifacts generated and appended to notes.")
    end

    it "flashes the error when generation fails" do
      allow(LLM::ArtifactGenerator).to receive(:call).and_return(success: false, error: "boom")

      post generate_artifacts_user_job_postings_path, params: { job_posting_id: job_posting.id }

      expect(flash[:alert]).to eq("Generation failed: boom")
    end
  end
end
