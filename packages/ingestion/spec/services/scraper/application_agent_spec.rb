# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scraper::ApplicationAgent do
  let(:user) { create(:user) }
  let(:job_posting) { create(:job_posting, target_url: "https://example.com/apply") }

  before { create(:career_profile, user: user, resume_text: "Staff Engineer") }

  # 5 doubles model a genuine 5-level Playwright API chain (playwright ->
  # chromium -> browser -> page -> element) -- consolidating them would
  # hide that chain's real shape, not simplify it.
  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe ".call" do
    # Playwright's real API is generated per-session over an RPC channel
    # (define_channel_owner), not discoverable via reflection ahead of a
    # real connection -- instance_double's verification doesn't apply here,
    # so bare doubles are the deliberate choice, same reasoning as
    # Style/OpenStructUse elsewhere in this codebase.
    # rubocop:disable RSpec/VerifiedDoubles
    let(:mock_playwright) { double("Playwright") }
    let(:mock_browser) { double("Browser") }
    let(:mock_page) { double("Page") }
    let(:mock_element) { double("Element") }
    let(:mock_chromium) { double("Chromium") }

    before do
      allow(Playwright).to receive(:create).and_yield(mock_playwright)
      allow(mock_playwright).to receive(:chromium).and_return(mock_chromium)
      allow(mock_chromium).to receive(:launch).and_yield(mock_browser)
      allow(mock_browser).to receive(:new_page).and_return(mock_page)
      allow(mock_page).to receive(:goto)
      allow(mock_page).to receive(:query_selector).and_return(mock_element)
      allow(mock_element).to receive(:click)
      allow(mock_page).to receive(:wait_for_load_state)
      allow(mock_page).to receive(:fill)
    end

    it "attempts to auto-fill an application form" do
      result = described_class.call(job_posting, user)

      expect(result[:success]).to be true
      expect(mock_page).to have_received(:goto).with(job_posting.target_url)
      expect(mock_page).to have_received(:query_selector).with(anything).at_least(:once)
      expect(mock_element).to have_received(:click)
      expect(mock_page).to have_received(:wait_for_load_state).with(state: "networkidle")
    end
    # rubocop:enable RSpec/VerifiedDoubles
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
