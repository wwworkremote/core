# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailIngestion::CanonicalUrlResolver do
  describe "#call" do
    it "returns the original URL unchanged when there is no redirect" do
      url = "https://example.com/jobs/1"
      stub_request(:get, url).to_return(status: 200)

      expect(described_class.new(url).call).to eq(url)
    end

    it "follows a single redirect to its destination" do
      start_url = "https://short.link/abc"
      target_url = "https://example.com/jobs/1"
      stub_request(:get, start_url).to_return(status: 301, headers: { "location" => target_url })
      stub_request(:get, target_url).to_return(status: 200)

      expect(described_class.new(start_url).call).to eq(target_url)
    end

    it "resolves a relative Location header against the current URL" do
      start_url = "https://example.com/redirect"
      stub_request(:get, start_url).to_return(status: 302, headers: { "location" => "/jobs/1" })
      stub_request(:get, "https://example.com/jobs/1").to_return(status: 200)

      expect(described_class.new(start_url).call).to eq("https://example.com/jobs/1")
    end

    it "stops and keeps the current URL when a redirect has no Location header" do
      url = "https://example.com/broken-redirect"
      stub_request(:get, url).to_return(status: 301, headers: {})

      expect(described_class.new(url).call).to eq(url)
    end

    it "stops and keeps the last resolved URL when the request raises" do
      url = "https://example.com/unreachable"
      stub_request(:get, url).to_raise(Faraday::ConnectionFailed.new("boom"))

      expect(described_class.new(url).call).to eq(url)
    end

    it "caps redirect-following at 5 hops" do
      6.times do |n|
        stub_request(:get, "https://example.com/hop#{n}")
          .to_return(status: 301, headers: { "location" => "https://example.com/hop#{n + 1}" })
      end
      stub_request(:get, "https://example.com/hop6").to_return(status: 200)

      expect(described_class.new("https://example.com/hop0").call).to eq("https://example.com/hop5")
    end

    it "strips known tracking params from the final URL" do
      url = "https://example.com/jobs/1?utm_source=newsletter&utm_medium=email&id=42"
      stub_request(:get, url).to_return(status: 200)

      expect(described_class.new(url).call).to eq("https://example.com/jobs/1?id=42")
    end

    it "drops the query entirely when only tracking params were present" do
      url = "https://example.com/jobs/1?utm_source=newsletter"
      stub_request(:get, url).to_return(status: 200)

      expect(described_class.new(url).call).to eq("https://example.com/jobs/1")
    end
  end
end
