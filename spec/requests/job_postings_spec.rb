# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Job Postings" do
  let(:origin) { Origin.find_or_create_by!(name: "Test Origin") }
  let(:source) { Source.find_or_create_by!(signature: "test-source", origin: origin) }
  let!(:job) {
    JobPosting.create!(
      signature: "test-1",
      title: "Senior Ruby Developer",
      company: "Acme Corp",
      published_at: 1.day.ago,
      source: source,
      status: "none"
    )
  }

  describe "GET /job_postings" do
    it "returns a success response" do
      get job_postings_path
      expect(response).to be_successful
      expect(response.body).to include("Senior Ruby Developer")
    end

    it "shows the linked Company's name when company_name is blank" do
      company = create(:company, name: "Sparta Commodities")
      JobPosting.create!(signature: "test-company-id-only", title: "Staff Backend Engineer",
                         company_id: company.id, published_at: Time.current, status: "none")

      get job_postings_path
      expect(response.body).to include("Sparta Commodities")
      expect(response.body).not_to include("/job_postings\">/job_postings")
    end

    it "falls back to a plain label instead of a broken link when no company is known" do
      JobPosting.create!(signature: "test-no-company", title: "Mystery Role",
                         published_at: Time.current, status: "none")

      get job_postings_path
      expect(response.body).to include("Unknown company")
      expect(response.body).not_to include("/job_postings\">/job_postings")
    end

    it "filters results by search query" do
      JobPosting.create!(
        signature: "test-2",
        title: "Python Architect",
        company: "Other Co",
        published_at: Time.current,
        status: "none"
      )
      get job_postings_path, params: { q: "Ruby" }
      expect(response.body).to include("Senior Ruby Developer")
      expect(response.body).not_to include("Python Architect")
    end

    it "combines a search query with another active filter, not just the query alone" do
      JobPosting.create!(
        signature: "test-contract-ruby",
        title: "Contract Ruby Developer",
        company: "Acme Corp",
        published_at: Time.current,
        status: "none",
        data: { "employment_type" => "Contract" }
      )
      get job_postings_path, params: { q: "Ruby", contract: "1" }
      expect(response.body).to include("Contract Ruby Developer")
      expect(response.body).not_to include("Senior Ruby Developer")
    end

    it "filters out ignored, purged, and expired jobs by default" do
      create(:job_posting, signature: "ignored-1", title: "Ignored Job", status: "ignored")
      create(:job_posting, signature: "purged-1", title: "Purged Job", status: "purged")
      create(:job_posting, signature: "expired-1", title: "Expired Job", status: "expired", published_at: 1.year.ago)

      get job_postings_path
      expect(response.body).not_to include("Ignored Job")
      expect(response.body).not_to include("Purged Job")
      expect(response.body).not_to include("Expired Job")
    end

    it "orders postings with a null published_at after ones with a value" do
      create(:job_posting, signature: "null-published", title: "Null Published Job", status: "none", published_at: nil)

      get job_postings_path
      null_index = response.body.index("Null Published Job")
      recent_index = response.body.index("Senior Ruby Developer")
      expect(null_index).to be_present
      expect(recent_index).to be < null_index
    end

    it "filters to a role family when role_family=engineering_management" do
      create(:job_posting, signature: "manager-1", title: "Engineering Manager, Platform", published_at: Time.current)

      get job_postings_path, params: { role_family: "engineering_management" }
      expect(response.body).to include("Engineering Manager, Platform")
      expect(response.body).not_to include("Senior Ruby Developer")
    end

    it "filters to a different role family when role_family=staff_plus_ic" do
      create(:job_posting, signature: "staff-1", title: "Staff Software Engineer, Platform", published_at: Time.current)

      get job_postings_path, params: { role_family: "staff_plus_ic" }
      expect(response.body).to include("Staff Software Engineer, Platform")
      expect(response.body).not_to include("Senior Ruby Developer")
    end

    it "ignores an unrecognized role_family value rather than erroring" do
      get job_postings_path, params: { role_family: "not-a-real-family" }
      expect(response).to be_successful
      expect(response.body).to include("Senior Ruby Developer")
    end

    it "filters by location text" do
      create(:job_posting, signature: "chicago-1", title: "Chicago Loop Engineer",
                           location: "Chicago, IL", published_at: Time.current)

      get job_postings_path, params: { location: "Chicago" }
      expect(response.body).to include("Chicago Loop Engineer")
      expect(response.body).not_to include("Senior Ruby Developer")
    end

    it "filters to remote postings via the structured data flag, not just location text" do
      # Regression companion to Geo::CommuteZone's key fix -- the primary
      # enrichment pipeline (extension captures included) writes
      # data["remote"], and this filter needs to honor that even when the
      # location string itself never says "remote".
      create(:job_posting, signature: "remote-flagged", title: "Flagged Remote Engineer",
                           location: "Austin, TX", data: { "remote" => true }, published_at: Time.current)

      get job_postings_path, params: { remote: "1" }
      expect(response.body).to include("Flagged Remote Engineer")
      expect(response.body).not_to include("Senior Ruby Developer")
    end

    it "filters to contract postings when contract=1" do
      create(:job_posting, signature: "contract-1", title: "Contract DevOps Engineer",
                           data: { "employment_type" => "Contract" }, published_at: Time.current)

      get job_postings_path, params: { contract: "1" }
      expect(response.body).to include("Contract DevOps Engineer")
      expect(response.body).not_to include("Senior Ruby Developer")
    end

    it "combines location and remote as OR, not AND" do
      create(:job_posting, signature: "chicago-2", title: "Chicago Onsite Engineer",
                           location: "Chicago, IL", published_at: Time.current)
      create(:job_posting, signature: "remote-2", title: "Fully Remote Engineer",
                           location: "Remote", published_at: Time.current)

      get job_postings_path, params: { location: "Chicago", remote: "1" }
      expect(response.body).to include("Chicago Onsite Engineer")
      expect(response.body).to include("Fully Remote Engineer")
      expect(response.body).not_to include("Senior Ruby Developer")
    end
  end

  describe "GET /job_postings/:id" do
    it "returns a success response" do
      get job_posting_path(job)
      expect(response).to be_successful
      expect(response.body).to include("Senior Ruby Developer")
      expect(response.body).to include("Acme Corp")
    end

    it "shows the reformat button when the posting has a body and isn't already reformatting" do
      job.update!(body: "raw description text")
      get job_posting_path(job)
      expect(response.body).to include("Reformat with AI")
    end

    it "shows a pending indicator instead of the button while reformatting" do
      job.update!(body: "raw description text", data: { "reformatting" => true })
      get job_posting_path(job)
      expect(response.body).to include("Reformatting...")
      expect(response.body).not_to include("Reformat with AI")
    end

    it "prefers the AI-reformatted body over the raw body when present" do
      job.update!(body: "raw <b>text</b>", data: { "formatted_body" => "## Clean Heading" })
      get job_posting_path(job)
      expect(response.body).to include("Clean Heading")
    end
  end

  describe "POST /job_postings/:id/reformat" do
    before { ActiveJob::Base.queue_adapter = :test }

    it "marks the posting as reformatting and enqueues the background job" do
      job.update!(body: "raw description text")

      expect {
        post reformat_job_posting_path(job), as: :turbo_stream
      }.to have_enqueued_job(JobPostingReformatJob).with(job.id)

      expect(job.reload.data["reformatting"]).to be true
    end

    it "responds with a turbo stream replacing the description block" do
      job.update!(body: "raw description text")
      post reformat_job_posting_path(job), as: :turbo_stream
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include("Reformatting...")
    end
  end
end
