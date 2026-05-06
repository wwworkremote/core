# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scraper::Dice::ApiClient do
  let!(:source) { create(:job_boards_source, slug: "dice", name: "Dice") }
  let!(:query) { create(:job_boards_query, job_boards_source: source) }
  let(:client) { described_class.new }

  let(:dice_html) do
    <<~HTML
      <html>
        <body>
          <div class="card">
            <a class="card-title-link" id="dice-job-123" href="/job-detail/dice-job-123">Ruby Lead</a>
            <span data-cy="search-result-company-name">DiceCorp</span>
            <span class="card-location">Remote, US</span>
          </div>
        </body>
      </html>
    HTML
  end

  describe "#search" do
    it "fetches, parses, and stores Dice job documents" do
      page_fetch_double = instance_double(JobFetchers::PageFetch)
      allow(JobFetchers::PageFetch).to receive(:new).and_return(page_fetch_double)
      allow(page_fetch_double).to receive(:call).and_return({
                                                              content: dice_html,
                                                              final_url: "https://www.dice.com/jobs?q=Ruby+on+Rails&l=Remote"
                                                            })

      expect {
        client.search("Ruby on Rails", "Remote")
      }.to change(JobBoards::Document, :count).by(1)

      doc = JobBoards::Document.last
      parsed_doc = JSON.parse(doc.document)
      expect(parsed_doc["jobTitle"]).to eq("Ruby Lead")
      expect(parsed_doc["companyName"]).to eq("DiceCorp")
      expect(parsed_doc["external_id"]).to eq("dice-job-123")
    end
  end
end
