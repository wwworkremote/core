# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V0::JobPostings", type: :request do
  let!(:job) { create(:job_posting, title: "API Job") }

  describe "GET /api/v0/job_postings" do
    it "returns a list of job postings" do
      get api_v0_job_postings_path, as: :json
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json.first["title"]).to eq("API Job")
    end
  end

  describe "GET /api/v0/job_postings/:id" do
    it "returns a single job posting" do
      get api_v0_job_posting_path(job), as: :json
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(job.id)
    end
  end

  describe "POST /api/v0/job_postings" do
    let(:job_params) do
      {
        title: "New API Job",
        company: "API Corp",
        url: "https://api-example.com/1"
      }
    end

    it "creates a new job posting" do
      expect {
        post api_v0_job_postings_path, params: job_params, as: :json
      }.to change(JobPosting, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  describe "POST /api/v0/job_postings/:id/enrich" do
    it "enriches a job posting" do
      post enrich_api_v0_job_posting_path(job), params: { body: "Enriched body" }, as: :json
      expect(response).to be_successful
      job.reload
      expect(job.body).to eq("Enriched body")
      expect(job.crawl_status).to eq("enriched")
    end
  end
end
