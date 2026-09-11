# frozen_string_literal: true

require "rails_helper"

RSpec.describe RailsJobBoard::Fetcher, type: :service do
  let(:service) { described_class.new }
  let(:source) { JobBoards::Source.find_or_create_by!(slug: "rubyonrails", name: "Rails Job Board") }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }

  let(:feed_body) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Rails Job Board</title>
          <item>
            <title>Senior Backend Engineer at Acme Corp</title>
            <link>https://jobs.rubyonrails.org/jobs/1-senior-backend-engineer-acme-corp</link>
            <guid>https://jobs.rubyonrails.org/jobs/1-senior-backend-engineer-acme-corp</guid>
            <pubDate>Mon, 17 Aug 2026 19:06:59 +0000</pubDate>
            <description>&lt;p&gt;Build things with Rails.&lt;/p&gt;</description>
          </item>
          <item>
            <title>Staff Engineer, Platform at Widget Co</title>
            <link>https://jobs.rubyonrails.org/jobs/2-staff-engineer-platform-widget-co</link>
            <guid>https://jobs.rubyonrails.org/jobs/2-staff-engineer-platform-widget-co</guid>
            <pubDate>Sun, 16 Aug 2026 12:00:00 +0000</pubDate>
            <description>&lt;p&gt;Own the platform.&lt;/p&gt;</description>
          </item>
        </channel>
      </rss>
    XML
  end

  before do
    source
    query
    stub_request(:get, RailsJobBoard::Fetcher::FEED_URL).to_return(status: 200, body: feed_body)
  end

  describe "#call" do
    it "fetches RSS items and stores them as documents" do
      expect {
        service.call(force: true)
      }.to change(JobBoards::Document, :count).by(2)

      doc = JobBoards::Document.last
      data = JSON.parse(doc.document)

      expect(doc.source_id).to eq(source.id)
      expect(data).to have_key("guid")
      expect(data).to have_key("title")
      expect(data).to have_key("link")
      expect(data).to have_key("description")
    end

    it "is idempotent" do
      service.call(force: true)
      initial_count = JobBoards::Document.count

      service.call(force: true)
      expect(JobBoards::Document.count).to eq(initial_count)
    end

    it "trips the circuit breaker on 429 rate limit" do
      stub_request(:get, RailsJobBoard::Fetcher::FEED_URL).to_return(status: 429, body: "Too Many Requests")

      allow(Rails.logger).to receive(:warn).and_call_original

      service.call(force: true)
      result = service.call(force: true)
      expect(result).to eq(:locked)
      expect(Rails.logger).to have_received(:warn).with(/Circuit Breaker Tripped for rubyonrails/).at_least(:once)
    end
  end
end
