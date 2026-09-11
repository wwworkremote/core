# frozen_string_literal: true

require "rails_helper"

RSpec.describe Yc::Scraper do
  let(:scraper) { described_class.new }

  before { create(:job_boards_source, slug: "yc") }

  def html_with_data_page(json)
    %(<html><body><div data-page="#{CGI.escape_html(json.to_json)}"></div></body></html>)
  end

  def stub_yc_response(status: 200, body: "")
    stub_request(:get, Yc::Scraper::BASE_URL).to_return(status: status, body: body)
  end

  describe "#call" do
    it "creates a document for each embedded job and returns true" do
      job_data = { "props" => { "jobs" => [
        { "id" => 123, "title" => "Ruby Engineer", "companyName" => "Acme", "companyOneLiner" => "We build things",
          "location" => "Remote", "roleType" => "Full-time" }
      ] } }
      stub_yc_response(body: html_with_data_page(job_data))

      result = scraper.call

      expect(result).to be true
      document = JobBoards::Document.find_by(signature: "yc-123")
      expect(document).to be_present
      expect(JSON.parse(document.document)["title"]).to eq("Ruby Engineer")
    end

    it "returns false when the response is not 200" do
      stub_yc_response(status: 500)

      expect(scraper.call).to be false
    end

    it "returns false when the data-page attribute is missing" do
      stub_yc_response(body: "<html><body>no data here</body></html>")

      expect(scraper.call).to be false
    end

    it "returns :locked when the source is locked" do
      scraper.lock_source!("yc")

      expect(scraper.call).to eq(:locked)
    end
  end
end
