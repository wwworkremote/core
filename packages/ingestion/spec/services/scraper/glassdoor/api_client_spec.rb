# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scraper::Glassdoor::ApiClient do
  let!(:source) { create(:job_boards_source, slug: "glassdoor", name: "Glassdoor") }
  let(:client) { described_class.new }
  let(:glassdoor_html) do
    <<~HTML
      <html>
        <body>
          <li data-test="jobListing" data-id="gd-123">
            <a data-test="job-title">Staff Rails Engineer</a>
            <span data-test="employer-short-name">GlassCo</span>
            <span data-test="location">Remote</span>
            <span data-test="rating">4.5</span>
            <a data-test="job-link" href="/job-listing/some-job">View</a>
          </li>
        </body>
      </html>
    HTML
  end

  before { create(:job_boards_query, job_boards_source: source) }

  describe "#search" do
    it "fetches, parses, and stores Glassdoor job documents" do
      page_fetch_double = instance_double(JobFetchers::PageFetch)
      allow(JobFetchers::PageFetch).to receive(:new).and_return(page_fetch_double)
      allow(page_fetch_double).to receive(:call).and_return({
                                                              content: glassdoor_html,
                                                              final_url: "https://www.glassdoor.com/Job/jobs.htm"
                                                            })

      expect {
        client.search("Staff Ruby on Rails", "Remote")
      }.to change(JobBoards::Document, :count).by(1)

      doc = JobBoards::Document.last
      parsed_doc = JSON.parse(doc.document)
      expect(parsed_doc["jobTitle"]).to eq("Staff Rails Engineer")
      expect(parsed_doc["companyName"]).to eq("GlassCo")
      expect(parsed_doc["external_id"]).to eq("gd-123")
    end
  end
end
