# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V0::Outcomes" do
  let(:user) { create(:user) }
  # A minimal but real appStatusJobs row -- same shape captured live 2026-08-24
  # (see bin/import_indeed_applications and Applications::IndeedRowImporter).
  let(:base_indeed_row) do
    { "jobKey" => "abc123def456", "jobTitle" => "Staff Engineer",
      "company" => { "name" => "Acme Corp" }, "location" => "Remote",
      "jobUrl" => "https://www.indeed.com/viewjob?jk=abc123def456",
      "applyTime" => 1_755_000_000_000, "statuses" => { "candidateStatus" => { "status" => nil } } }
  end

  before { allow(User).to receive(:first).and_return(user) }


  def indeed_row(overrides = {})
    base_indeed_row.merge(overrides)
  end

  def post_indeed(rows)
    post "/api/v0/outcomes/indeed", params: { body: { appStatusJobs: rows } }, as: :json
  end

  describe "POST indeed" do
    it "creates a JobPosting and tracks it as applied for a row with no prior match" do
      expect { post_indeed([indeed_row]) }.to change(JobPosting, :count).by(1)

      expect(user.user_job_postings.sole.status).to eq("applied")
    end

    it "reports how many rows were imported and how many carried an outcome" do
      rejected = indeed_row("jobKey" => "rejected1",
                            "statuses" => { "candidateStatus" => { "status" => "REJECTED" } })
      silent = indeed_row("jobKey" => "silent1")

      post_indeed([rejected, silent])

      expect(response.parsed_body).to include("imported" => 2, "outcomes" => 1)
    end

    it "records the outcome on the matched UserJobPosting" do
      row = indeed_row("statuses" => { "candidateStatus" => { "status" => "REJECTED" } })

      post_indeed([row])

      tracked = user.user_job_postings.sole
      expect(tracked).to have_attributes(outcome: "rejected", outcome_source: "employer")
      expect(tracked.outcome_at).to be_present
    end

    it "matches an existing posting by company+title rather than duplicating it" do
      create(:job_posting, company_name: "Acme Corp", title: "Staff Engineer", target_url: "https://elsewhere.example/x")

      expect { post_indeed([indeed_row]) }.not_to change(JobPosting, :count)
    end

    it "is idempotent -- re-posting the same row does not duplicate the tracked application" do
      post_indeed([indeed_row])

      expect { post_indeed([indeed_row]) }.not_to change(UserJobPosting, :count)
    end

    it "refuses an empty payload instead of silently no-op'ing" do
      post_indeed([])

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
