# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scraper::Crawler::Discovery do
  let(:board_name) { "test-board" }
  let(:base_url) { "http://example.com/jobs" }
  let(:discovery) { described_class.new(board_name, base_url) }

  describe "#call" do
    it "handles Playwright errors gracefully" do
      allow(Playwright).to receive(:create).and_raise(Playwright::Error.new(message: "Timeout!"))
      allow(Rails.logger).to receive(:error)

      expect { discovery.call }.not_to raise_error
      expect(Rails.logger).to have_received(:error).with(/Playwright error/)
    end

    it "handles unexpected errors gracefully" do
      allow(Playwright).to receive(:create).and_raise(StandardError.new("Boom!"))
      allow(Rails.logger).to receive(:error)

      expect { discovery.call }.not_to raise_error
      expect(Rails.logger).to have_received(:error).with(/Unexpected error/)
    end

    it "discovers and persists links" do
      selector = "a.job-link"
      page = stub_successful_crawl(selector)

      expect {
        described_class.new("Cord", "https://cord.com/jobs", selector: selector).call
      }.to change(DiscoveryLink, :count).by(2)

      expect(page).to have_received(:eval_on_selector_all).with(selector, anything)
      expect(DiscoveryLink.last.url).to eq("https://cord.com/jobs/2")
    end

    # Playwright's real API is generated per-session over an RPC channel
    # (define_channel_owner), not discoverable via reflection ahead of a
    # real connection -- instance_double's verification doesn't apply here,
    # so bare doubles are the deliberate choice, same reasoning as
    # Style/OpenStructUse elsewhere in this codebase. Both helpers below are
    # flat mock-wiring setup with no real logic to extract further.
    # rubocop:disable RSpec/VerifiedDoubles, Metrics/MethodLength, Metrics/AbcSize
    def stub_playwright_chain
      playwright, chromium, browser, page = %w[Playwright Chromium Browser Page].map { |n| double(n) }

      allow(Playwright).to receive(:create).and_yield(playwright)
      allow(playwright).to receive(:chromium).and_return(chromium)
      allow(chromium).to receive(:launch).and_yield(browser)
      allow(browser).to receive(:new_page).and_return(page)

      page
    end

    def stub_successful_crawl(selector)
      page = stub_playwright_chain
      allow(page).to receive(:default_timeout=)
      allow(page).to receive(:goto)
      allow(page).to receive(:wait_for_load_state)
      links = ["https://cord.com/jobs/1", "https://cord.com/jobs/2"]
      allow(page).to receive(:eval_on_selector_all).with(selector, anything).and_return(links)
      page
    end
    # rubocop:enable RSpec/VerifiedDoubles, Metrics/MethodLength, Metrics/AbcSize
  end
end
