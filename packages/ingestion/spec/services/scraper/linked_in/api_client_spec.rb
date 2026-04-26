# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scraper::LinkedIn::ApiClient do
  let!(:source) { create(:job_boards_source, slug: "linkedin", name: "LinkedIn") }
  let!(:query) { create(:job_boards_query, job_boards_source: source) }
  let(:client) { described_class.new }
  
  let(:linkedin_html) do
    <<~HTML
      <html>
        <body>
          <div class="base-card">
            <h3 class="base-search-card__title">Staff Software Engineer</h3>
            <h4 class="base-search-card__subtitle">CloudCo</h4>
            <span class="job-search-card__location">United States</span>
            <a class="base-card__full-link" href="https://www.linkedin.com/jobs/view/9988776655?refId=abc">View Job</a>
          </div>
        </body>
      </html>
    HTML
  end

  describe "#search" do
    it "fetches, parses, and stores LinkedIn job documents" do
      page_fetch_double = instance_double(JobFetchers::PageFetch)
      allow(JobFetchers::PageFetch).to receive(:new).and_return(page_fetch_double)
      allow(page_fetch_double).to receive(:call).and_return({
        content: linkedin_html,
        final_url: "https://www.linkedin.com/jobs/search?keywords=Staff+Ruby+Engineer&location=Remote"
      })

      expect {
        client.search("Staff Ruby Engineer", "Remote")
      }.to change(JobBoards::Document, :count).by(1)

      doc = JobBoards::Document.last
      parsed_doc = JSON.parse(doc.document)
      expect(parsed_doc["jobTitle"]).to eq("Staff Software Engineer")
      expect(parsed_doc["companyName"]).to eq("CloudCo")
      expect(parsed_doc["external_id"]).to eq("9988776655")
    end
  end
end
