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

    it "records a decline reason alongside a rejected outcome" do
      post user_job_postings_path,
           params: { job_posting_id: job_posting.id, outcome: "rejected",
                     outcome_reason: "Not enough Rails experience" }

      expect(UserJobPosting.last.outcome).to eq("rejected")
      expect(UserJobPosting.last.outcome_reason).to eq("Not enough Rails experience")
    end

    it "attaches evidence alongside a rejected outcome" do
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.txt"), "text/plain")

      post user_job_postings_path,
           params: { job_posting_id: job_posting.id, outcome: "rejected", outcome_evidence: file }

      expect(UserJobPosting.last.outcome_evidence).to be_attached
    end

    it "marks rejected with no reason or evidence exactly as before" do
      post user_job_postings_path, params: { job_posting_id: job_posting.id, outcome: "rejected" }

      expect(UserJobPosting.last.outcome).to eq("rejected")
      expect(UserJobPosting.last.outcome_reason).to be_nil
      expect(UserJobPosting.last.outcome_evidence).not_to be_attached
    end

    it "starts the company's decline cooldown when marked rejected" do
      company = create(:company)
      posting = create(:job_posting, company_id: company.id)

      post user_job_postings_path, params: { job_posting_id: posting.id, outcome: "rejected" }

      expect(company.reload.last_declined_at).to be_present
      expect(company.in_cooldown?).to be true
    end

    it "does not touch the company's cooldown for a non-rejected outcome" do
      company = create(:company)
      posting = create(:job_posting, company_id: company.id)

      post user_job_postings_path, params: { job_posting_id: posting.id, outcome: "offered" }

      expect(company.reload.last_declined_at).to be_nil
    end

    it "does not raise when the posting has no resolved company" do
      expect {
        post user_job_postings_path, params: { job_posting_id: job_posting.id, outcome: "rejected" }
      }.not_to raise_error
    end
  end

  describe "PATCH /user_job_postings/:id" do
    it "updates and redirects" do
      ujp = user.user_job_postings.create!(job_posting: job_posting)

      patch user_job_posting_path(ujp), params: { user_job_posting: { notes: "Great fit" } }

      expect(ujp.reload.notes).to eq("Great fit")
      expect(response).to redirect_to(user_job_postings_path)
    end

    it "clearing the outcome also clears the reason and evidence" do
      ujp = user.user_job_postings.create!(job_posting: job_posting, outcome: "rejected",
                                           outcome_reason: "Not a fit")
      ujp.outcome_evidence.attach(io: StringIO.new("evidence"), filename: "evidence.txt", content_type: "text/plain")

      patch user_job_posting_path(ujp),
            params: { user_job_posting: { outcome: nil, outcome_at: nil, outcome_source: nil,
                                          outcome_reason: nil, outcome_evidence: nil } }

      ujp.reload
      expect(ujp.outcome).to be_nil
      expect(ujp.outcome_reason).to be_nil
      expect(ujp.outcome_evidence).not_to be_attached
    end

    it "cannot set a real outcome directly via PATCH, only clear one" do
      ujp = user.user_job_postings.create!(job_posting: job_posting)

      patch user_job_posting_path(ujp), params: { user_job_posting: { outcome: "rejected", outcome_reason: "sneaky" } }

      expect(ujp.reload.outcome).to be_nil
    end
  end

  describe "GET /user_job_postings" do
    it "shows a Rejected badge for a rejected outcome" do
      user.user_job_postings.create!(job_posting: job_posting, status: "applied", outcome: "rejected")
      get user_job_postings_path
      expect(response.body).to include("Rejected")
    end

    it "shows a Reviewed badge for a reviewed outcome" do
      user.user_job_postings.create!(job_posting: job_posting, status: "applied", outcome: "reviewed")
      get user_job_postings_path
      expect(response.body).to include("Reviewed")
    end

    it "shows a Posting closed badge for a closed outcome" do
      user.user_job_postings.create!(job_posting: job_posting, status: "applied", outcome: "closed")
      get user_job_postings_path
      expect(response.body).to include("Posting closed")
    end

    it "shows no outcome badge when there is no outcome yet" do
      user.user_job_postings.create!(job_posting: job_posting, status: "applied")
      get user_job_postings_path
      expect(response.body).not_to include("Rejected")
      expect(response.body).not_to include("Reviewed")
      expect(response.body).not_to include("Posting closed")
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

      expect(flash[:notice]).to eq("Bespoke application artifacts generated.")
    end

    it "flashes the error when generation fails" do
      allow(LLM::ArtifactGenerator).to receive(:call).and_return(success: false, error: "boom")

      post generate_artifacts_user_job_postings_path, params: { job_posting_id: job_posting.id }

      expect(flash[:alert]).to eq("Generation failed: boom")
    end
  end

  describe "POST /user_job_postings/generate_interview_prep" do
    it "flashes success and redirects when generation succeeds" do
      allow(LLM::InterviewPrepGenerator).to receive(:call).and_return(success: true)

      post generate_interview_prep_user_job_postings_path, params: { job_posting_id: job_posting.id }

      expect(flash[:notice]).to eq("Interview prep pack generated.")
      expect(response).to be_redirect
    end

    it "passes force: true through on regenerate" do
      allow(LLM::InterviewPrepGenerator).to receive(:call).and_return(success: true)

      post generate_interview_prep_user_job_postings_path,
           params: { job_posting_id: job_posting.id, force: "true" }

      expect(LLM::InterviewPrepGenerator).to have_received(:call).with(user, job_posting, force: true)
    end

    it "flashes the error when generation fails" do
      allow(LLM::InterviewPrepGenerator).to receive(:call).and_return(success: false, error: "boom")

      post generate_interview_prep_user_job_postings_path, params: { job_posting_id: job_posting.id }

      expect(flash[:alert]).to eq("Generation failed: boom")
    end
  end
end
