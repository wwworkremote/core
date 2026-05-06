# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scraper::Indeed::ApiClient do
  let!(:source) { create(:job_boards_source, slug: "indeed", name: "Indeed") }
  let!(:query) { create(:job_boards_query, job_boards_source: source) }
  let(:client) { described_class.new }

  let(:indeed_html) do
    <<~HTML
      <html>
        <body>
          <div class="job_seen_beacon">
            <h2 class="jobTitle"><a data-jk="jk-123">Senior Ruby Engineer</a></h2>
            <span data-testid="company-name">RemoteCorp</span>
            <div data-testid="text-location">Chicago, IL</div>
          </div>
        </body>
      </html>
    HTML
  end

  describe "#search" do
    it "fetches, parses, and stores job documents" do
      # 1. Stub the PageFetch call
      page_fetch_double = instance_double(JobFetchers::PageFetch)
      allow(JobFetchers::PageFetch).to receive(:new).and_return(page_fetch_double)
      allow(page_fetch_double).to receive(:call).and_return({
                                                              content: indeed_html,
                                                              final_url: "https://www.indeed.com/jobs?q=Staff+Engineer&l=Remote"
                                                            })

      expect {
        client.search("Staff Engineer", "Remote")
      }.to change(JobBoards::Document, :count).by(1)

      doc = JobBoards::Document.last
      parsed_doc = JSON.parse(doc.document)
      expect(parsed_doc["jobTitle"]).to eq("Senior Ruby Engineer")
      expect(parsed_doc["companyName"]).to eq("RemoteCorp")
      expect(parsed_doc["external_id"]).to eq("jk-123")
    end

    it "is idempotent based on signature" do
      page_fetch_double = instance_double(JobFetchers::PageFetch)
      allow(JobFetchers::PageFetch).to receive(:new).and_return(page_fetch_double)
      allow(page_fetch_double).to receive(:call).and_return({ content: indeed_html })

      client.search("Staff Engineer", "Remote")
      expect(JobBoards::Document.count).to eq(1)

      client.search("Staff Engineer", "Remote")
      expect(JobBoards::Document.count).to eq(1)
    end
  end
end
