# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::Client do
  let(:slug) { "test-board" }
  let(:client) { described_class.new(slug) }
  let(:url) { "https://api.testboard.com/jobs" }

  before do
    # Ensure source exists for ApiGuard
    create(:job_boards_source, slug: slug)
  end

  describe "#get" do
    it "skips the request if the source is locked" do
      client.lock_source!(slug, duration: 10.minutes)
      
      expect(Faraday).not_to receive(:new)
      expect(client.get(url)).to be_nil
    end

    it "locks the source on 429 Rate Limit" do
      stub_request(:get, url).to_return(status: 429, headers: { "Retry-After" => "3600" })
      
      expect(client).to receive(:lock_source!).with(slug, duration: 3600.seconds).and_call_original
      
      result = client.get(url)
      expect(result).to be_nil
      expect(client.source_locked?(slug)).to be true
    end

    it "handles connection errors gracefully" do
      stub_request(:get, url).to_raise(Faraday::ConnectionFailed.new("Connection refused"))
      
      expect(Rails.logger).to receive(:error).with(/Connection error/)
      result = client.get(url)
      expect(result).to be_nil
    end

    it "successfully returns response for 200 OK" do
      stub_request(:get, url).to_return(status: 200, body: '{"ok": true}')
      
      result = client.get(url)
      expect(result.status).to eq(200)
      expect(result.body).to eq('{"ok": true}')
    end
  end
end
