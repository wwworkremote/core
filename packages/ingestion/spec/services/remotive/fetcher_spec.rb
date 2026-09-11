# frozen_string_literal: true

require "rails_helper"

RSpec.describe Remotive::Fetcher, type: :service do
  let(:service) { described_class.new }
  let(:source) { JobBoards::Source.find_or_create_by!(slug: "remotive", name: "Remotive") }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }

  describe "#call", vcr: { cassette_name: "remotive_fetch", allow_playback_repeats: true } do
    before do
      # Ensure source and query exist
      source
      query
    end

    it "fetches remote jobs and stores them as documents" do
      expect {
        service.call(force: true)
      }.to change(JobBoards::Document, :count)

      doc = JobBoards::Document.last
      data = JSON.parse(doc.document)

      expect(doc.source_id).to eq(source.id)
      expect(data).to have_key("id")
      expect(data).to have_key("company_name")
      expect(data).to have_key("title")
    end

    it "is idempotent and does not create duplicate documents" do
      service.call # First run
      initial_count = JobBoards::Document.count

      service.call # Second run
      expect(JobBoards::Document.count).to eq(initial_count)
    end

    it "trips the circuit breaker on 429 rate limit" do
      # We must turn off VCR for this specific test to stub manually
      VCR.eject_cassette
      VCR.turned_off do
        stub_request(:get, /remotive.com/).to_return(status: 429, body: "Too Many Requests")

        allow(Rails.logger).to receive(:warn).and_call_original

        service.call(force: true)
        result = service.call(force: true)
        expect(result).to eq(:locked)
        expect(Rails.logger).to have_received(:warn).with(/Circuit Breaker Tripped for remotive/).at_least(:once)
      end
    end
  end
end
