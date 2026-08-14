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
  end
end
