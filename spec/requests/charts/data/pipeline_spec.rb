# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Charts::Data::Pipelines", type: :request do
  let!(:source) { create(:job_boards_source, name: "Arbeitnow") }
  let!(:doc) { create(:job_boards_document, job_boards_source: source, created_at: 1.day.ago) }
  let!(:job) { create(:job_posting, data: { "ai_category" => "Engineering" }, embedding: [0.1] * 3584) }

  describe "GET /charts/data/pipeline/health" do
    it "returns health data as JSON" do
      get charts_data_pipeline_health_path
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json["Arbeitnow"]).to eq(1)
    end
  end

  describe "GET /charts/data/pipeline/funnel" do
    it "returns funnel data as JSON" do
      get charts_data_pipeline_funnel_path
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json.to_h["Raw Documents"]).to eq(1)
      expect(json.to_h["Job Postings"]).to eq(1)
      expect(json.to_h["AI Classified"]).to eq(1)
      expect(json.to_h["Vector Indexed"]).to eq(1)
    end
  end
end
