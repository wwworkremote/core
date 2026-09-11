# frozen_string_literal: true

require "rails_helper"

RSpec.describe Adzuna::Fetcher, type: :service do
  let(:service) { described_class.new }
  let(:source) { JobBoards::Source.find_or_create_by!(slug: "adzuna", name: "Adzuna") }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }

  describe "#call" do
    before do
      source
      query
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("ADZUNA_APPLICATION_ID", nil).and_return("test_id")
      allow(ENV).to receive(:fetch).with("ADZUNA_APPLICATION_KEY", nil).and_return("test_key")

      stub_request(:get, /api.adzuna.com/)
        .to_return(status: 200, body: {
          results: [
            { id: "123", title: "Remote Ruby Dev", company: { display_name: "Test Co" } }
          ]
        }.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "fetches JSON jobs and stores them as documents" do
      # Debug: check if source exists
      expect(JobBoards::Source.find_by(slug: "adzuna")).to be_present

      expect {
        service.call(force: true)
      }.to change(JobBoards::Document, :count).by(1)

      doc = JobBoards::Document.last
      data = JSON.parse(doc.document)

      expect(doc.source_id).to eq(source.id)
      expect(data).to have_key("id")
      expect(data).to have_key("title")
    end

    it "is idempotent" do
      service.call(force: true)
      initial_count = JobBoards::Document.count

      service.call(force: true)
      expect(JobBoards::Document.count).to eq(initial_count)
    end

    it "trips the circuit breaker on 429 rate limit" do
      stub_request(:get, /api.adzuna.com/).to_return(status: 429, body: "Too Many Requests")

      allow(Rails.logger).to receive(:warn).and_call_original

      # First call returns false because of the return false if response.nil?
      service.call(force: true)

      # Second call should be locked
      result = service.call(force: true)
      expect(result).to eq(:locked)
      expect(Rails.logger).to have_received(:warn).with(/Circuit Breaker Tripped for adzuna/).at_least(:once)
    end

    it "handles missing credentials gracefully" do
      allow(ENV).to receive(:fetch).with("ADZUNA_APPLICATION_ID", nil).and_return(nil)
      allow(Rails.logger).to receive(:error).and_call_original

      result = service.call(force: true)

      expect(result).to be false
      expect(Rails.logger).to have_received(:error).with(/Adzuna API credentials missing/)
    end
  end
end
