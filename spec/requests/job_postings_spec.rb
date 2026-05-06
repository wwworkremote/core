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

    it "filters out ignored and purged jobs by default" do
      create(:job_posting, signature: "ignored-1", title: "Ignored Job", status: "ignored")
      create(:job_posting, signature: "purged-1", title: "Purged Job", status: "purged")

      get job_postings_path
      expect(response.body).not_to include("Ignored Job")
      expect(response.body).not_to include("Purged Job")
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
