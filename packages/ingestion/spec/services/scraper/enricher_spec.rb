# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scraper::Enricher do
  let(:job_posting) { create(:job_posting, target_url: "https://example.com/job/1") }

  describe ".enrich_posting" do
    it "updates job posting with extracted data" do
      mock_fetch_result = {
        content: "<html><body>Job Content</body></html>",
        final_url: "https://example.com/job/1",
        fetch_mode: "playwright"
      }

      mock_extracted_data = {
        title: "Senior Ruby Engineer",
        company: "Tech Corp",
        body: "Full job description.",
        location: "Remote"
      }

      expect_any_instance_of(JobFetchers::PageFetch).to receive(:call).and_return(mock_fetch_result)
      expect_any_instance_of(JobFetchers::CanonicalJobExtractor).to receive(:call).and_return(mock_extracted_data)

      described_class.enrich_posting(job_posting)

      job_posting.reload
      expect(job_posting.body).to eq("Full job description.")
      expect(job_posting.crawl_status).to eq("enriched")
      expect(job_posting.enriched_at).to be_present
    end
  end
end
