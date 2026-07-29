# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobFetchers::PageFetch do
  let(:url) { "https://example.com/jobs/1" }
  let(:fetcher) { described_class.new(url) }

  describe "#call" do
    it "returns the static fetch when the content looks legitimate" do
      stub_request(:get, url).to_return(status: 200, body: "x" * 2001)

      result = fetcher.call

      expect(result[:fetch_mode]).to eq("static")
      expect(result[:final_url]).to eq(url)
      expect(result[:content].length).to eq(2001)
    end

    it "falls through to Playwright when the static body is too short" do
      stub_request(:get, url).to_return(status: 200, body: "too short")
      allow(Playwright).to receive(:create)

      fetcher.call

      expect(Playwright).to have_received(:create)
    end

    it "falls through to Playwright when the static body looks like a bot-check page" do
      stub_request(:get, url).to_return(status: 200, body: "Checking your browser #{'x' * 2000}")
      allow(Playwright).to receive(:create)

      fetcher.call

      expect(Playwright).to have_received(:create)
    end

    it "falls through to Playwright when the static fetch raises" do
      stub_request(:get, url).to_raise(Faraday::ConnectionFailed.new("boom"))
      allow(Playwright).to receive(:create)

      fetcher.call

      expect(Playwright).to have_received(:create)
    end
  end

  # Playwright's real API is generated per-session over an RPC channel, not
  # discoverable via reflection ahead of a real connection -- bare doubles
  # are the deliberate choice, same reasoning as Scraper::ApplicationAgent's
  # spec and Style/OpenStructUse elsewhere in this codebase. The 6-level
  # chain (playwright -> chromium -> browser -> context -> page ->
  # interceptor) is what's actually being driven; consolidating the
  # doubles would hide that shape, not simplify it.
  # rubocop:disable RSpec/VerifiedDoubles, RSpec/MultipleMemoizedHelpers
  describe "#call falling through to Playwright" do
    let(:mock_playwright) { double("Playwright") }
    let(:mock_chromium) { double("Chromium") }
    let(:mock_browser) { double("Browser") }
    let(:mock_context) { double("Context") }
    let(:mock_page) { double("Page") }
    let(:mock_interceptor) { instance_double(Scraper::Crawler::ApiInterceptor, start_capturing: true, captured_calls: []) }

    before do
      stub_request(:get, url).to_return(status: 200, body: "x")
      allow(Playwright).to receive(:create).and_yield(mock_playwright)
      allow(mock_playwright).to receive(:chromium).and_return(mock_chromium)
      allow(mock_chromium).to receive(:launch).and_yield(mock_browser)
      allow(mock_browser).to receive(:new_context).and_return(mock_context)
      allow(mock_context).to receive(:new_page).and_return(mock_page)
      allow(Scraper::Crawler::ApiInterceptor).to receive(:new).and_return(mock_interceptor)
      allow(mock_page).to receive(:goto)
      allow(mock_page).to receive(:wait_for_selector)
      allow(mock_page).to receive_messages(content: "<html>Rendered</html>", url: "https://example.com/jobs/1/final")
      allow(fetcher).to receive(:sleep)
    end

    it "returns rendered content, final URL, and captured API calls" do
      result = fetcher.call

      expect(result[:content]).to eq("<html>Rendered</html>")
      expect(result[:final_url]).to eq("https://example.com/jobs/1/final")
      expect(result[:fetch_mode]).to eq("playwright")
      expect(result[:api_calls]).to eq([])
    end

    it "continues when waiting for a content selector times out" do
      allow(mock_page).to receive(:wait_for_selector).and_raise(Playwright::TimeoutError.new(message: "timeout"))

      result = fetcher.call

      expect(result[:fetch_mode]).to eq("playwright")
    end

    it "returns nil when Playwright itself raises" do
      allow(Playwright).to receive(:create).and_raise(StandardError, "playwright down")

      expect(fetcher.call).to be_nil
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles, RSpec/MultipleMemoizedHelpers
end
