# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V0::JobPostings" do
  let!(:job) { create(:job_posting, title: "API Job") }

  describe "GET /api/v0/job_postings" do
    it "returns a list of job postings" do
      get api_v0_job_postings_path, as: :json
      expect(response).to be_successful
      json = response.parsed_body
      expect(json.first["title"]).to eq("API Job")
    end
  end

  describe "GET /api/v0/job_postings/:id" do
    it "returns a single job posting" do
      get api_v0_job_posting_path(job), as: :json
      expect(response).to be_successful
      json = response.parsed_body
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

    it "upserts the existing record when the signature already exists" do
      expect {
        post api_v0_job_postings_path, params: job_params.merge(signature: job.signature), as: :json
      }.not_to change(JobPosting, :count)

      expect(response).to have_http_status(:created)
      expect(job.reload.title).to eq("New API Job")
    end

    it "returns errors when the signature is blank" do
      post api_v0_job_postings_path, params: job_params.merge(signature: ""), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      json = response.parsed_body
      expect(json["success"]).to be false
      expect(json["errors"]).to include("Signature can't be blank")
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

    it "persists the posting identity sent by an extension re-read" do
      post enrich_api_v0_job_posting_path(job), params: {
        title: "Principal Software Engineer",
        company: "Cengage",
        location: "United States",
        target_url: "https://cengage.wd5.myworkdayjobs.com/CengageNorthAmericaCareers/job/United-States/Principal-Software-Engineer_R2026-711",
        body: "Principal posting body",
        data: { employment_type: "Full-time", remote: true }
      }, as: :json

      expect(response).to be_successful
      job.reload
      expect(job.title).to eq("Principal Software Engineer")
      expect(job.company_name).to eq("Cengage")
      expect(job.location).to eq("United States")
      expect(job.target_url).to include("Principal-Software-Engineer_R2026-711")
      expect(job.body).to eq("Principal posting body")
      expect(job.data).to include("employment_type" => "Full-time", "remote" => true)
    end

    it "returns errors when enrichment fails" do
      allow(JobPosting).to receive(:find).and_return(job)
      allow(job).to receive(:update) do
        job.errors.add(:body, "is invalid")
        false
      end

      post enrich_api_v0_job_posting_path(job), params: { body: "x" }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      json = response.parsed_body
      expect(json["success"]).to be false
      expect(json["errors"]).to include("Body is invalid")
    end

    it "triggers realignment when realign is requested" do
      user = create(:user)
      allow(User).to receive(:first).and_return(user)
      allow(LLM::ProfileMatcher).to receive(:call)

      post enrich_api_v0_job_posting_path(job), params: { body: "Re-aligned", realign: true }, as: :json

      expect(LLM::ProfileMatcher).to have_received(:call).with(user, job)
    end

    it "does not trigger realignment when realign is not requested" do
      allow(LLM::ProfileMatcher).to receive(:call)

      post enrich_api_v0_job_posting_path(job), params: { body: "Not aligned" }, as: :json

      expect(LLM::ProfileMatcher).not_to have_received(:call)
    end
  end
end
