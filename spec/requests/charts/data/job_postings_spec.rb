# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Charts::Data::JobPostings" do
  describe "GET /charts/data/job_postings" do
    it "returns JSON data for job posting velocity" do
      create(:job_posting)
      get charts_data_job_postings_path
      expect(response).to be_successful
      data = response.parsed_body
      # group_by_hour returns keys as ISO8601 strings
      expect(data.values.sum).to eq(1)
    end

    it "supports 'days' parameter" do
      create(:job_posting, created_at: 2.days.ago)
      get charts_data_job_postings_path, params: { days: 7 }
      expect(response).to be_successful
      data = response.parsed_body
      expect(data.values.sum).to be >= 1
    end
  end

  describe "GET /charts/data/job_postings/corpus" do
    it "returns corpus data for the current month" do
      create(:job_posting, title: "Ruby Dev", body: "Need Rails expert.", published_at: Time.current)

      get charts_data_job_postings_corpus_path
      expect(response).to be_successful
      data = response.parsed_body
      expect(data["names"]).to include("ruby dev")
      expect(data["descriptions"]).to include("need rails expert.")
    end
  end
end
