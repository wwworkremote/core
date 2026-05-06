# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Charts::Data::Pipeline" do
  describe "GET /charts/data/pipeline/health" do
    it "returns JSON data for pipeline health" do
      source = create(:job_boards_source, name: "Test Board")
      create(:job_boards_document, job_boards_source: source)

      get charts_data_pipeline_health_path
      expect(response).to be_successful
      data = response.parsed_body
      expect(data["Test Board"]).to eq(1)
    end
  end

  describe "GET /charts/data/pipeline/funnel" do
    it "returns JSON data for pipeline funnel" do
      create(:job_boards_document)
      # Create an embedding with 3584 dimensions
      mock_embedding = Array.new(3584) { 0.1 }
      create(:job_posting, embedding: mock_embedding)

      get charts_data_pipeline_funnel_path
      expect(response).to be_successful
      data = response.parsed_body
      expect(data.assoc("Raw Documents")[1]).to eq(1)
      expect(data.assoc("Vector Indexed")[1]).to eq(1)
    end
  end
end
