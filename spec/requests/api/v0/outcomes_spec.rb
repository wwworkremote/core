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

  # A minimal but real applications.json row (see
  # bin/import_greenhouse_applications and Applications::GreenhouseRowImporter).
  let(:base_greenhouse_app) do
    { "id" => 987_654, "job_post_id" => 111_222, "job_title" => "Staff Engineer",
      "company_name" => "Acme Corp", "locations" => "Remote",
      "job_post_url" => "https://job-boards.greenhouse.io/acme/jobs/111222",
      "applied_at" => "2026-08-01T12:00:00-05:00", "currentStage" => nil, "inactive" => false }
  end

  before { allow(User).to receive(:first).and_return(user) }

  def indeed_row(overrides = {})
    base_indeed_row.merge(overrides)
  end

  def greenhouse_app(overrides = {})
    base_greenhouse_app.merge(overrides)
  end

  def post_indeed(rows)
    post "/api/v0/outcomes/indeed", params: { body: { appStatusJobs: rows } }, as: :json
  end

  def post_greenhouse(pages)
    post "/api/v0/outcomes/greenhouse", params: { pages: pages }, as: :json
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

  describe "POST greenhouse" do
    it "creates a JobPosting and tracks it as applied for an app with no prior match" do
      expect { post_greenhouse([{ "active" => { "applications" => [greenhouse_app] } }]) }
        .to change(JobPosting, :count).by(1)

      tracked = user.user_job_postings.sole
      expect(tracked.status).to eq("applied")
      expect(tracked.applied_at).to be_present
    end

    it "flattens and dedupes applications across multiple pages" do
      other = greenhouse_app("id" => 555, "job_post_id" => 999_888,
                             "job_post_url" => "https://job-boards.greenhouse.io/other/jobs/999888",
                             "company_name" => "Other Corp", "job_title" => "Different Role")
      page1 = { "active" => { "applications" => [greenhouse_app] } }
      page2 = { "active" => { "applications" => [other] } }

      expect { post_greenhouse([page1, page2]) }.to change(JobPosting, :count).by(2)
      expect(response.parsed_body).to include("imported" => 2)
    end

    it "does not import the same application twice across pages" do
      page1 = { "active" => { "applications" => [greenhouse_app] } }
      page2 = { "active" => { "applications" => [greenhouse_app] } }

      expect { post_greenhouse([page1, page2]) }.to change(JobPosting, :count).by(1)
    end

    it "reads an inactive bucket if present, defensively" do
      page = { "active" => { "applications" => [] }, "inactive" => { "applications" => [greenhouse_app] } }

      expect { post_greenhouse([page]) }.to change(JobPosting, :count).by(1)
    end

    it "records a rejection when currentStage says so" do
      app = greenhouse_app("currentStage" => "Rejected by employer")

      post_greenhouse([{ "active" => { "applications" => [app] } }])

      expect(user.user_job_postings.sole.outcome).to eq("rejected")
    end

    it "records closed, not rejected, for an inactive application with no stage detail" do
      app = greenhouse_app("inactive" => true)

      post_greenhouse([{ "active" => { "applications" => [] }, "inactive" => { "applications" => [app] } }])

      expect(user.user_job_postings.sole.outcome).to eq("closed")
    end

    it "reports no outcome for an application with no signal, honestly" do
      post_greenhouse([{ "active" => { "applications" => [greenhouse_app] } }])

      expect(response.parsed_body).to include("imported" => 1, "outcomes" => 0)
      expect(user.user_job_postings.sole.outcome).to be_nil
    end

    it "refuses a payload with no applications instead of silently no-op'ing" do
      post_greenhouse([{ "active" => { "applications" => [] } }])

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
