# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scraper::ApplicationAgent do
  let(:user) { create(:user) }
  let!(:career_profile) { create(:career_profile, user: user, resume_text: "Staff Engineer") }
  let(:job_posting) { create(:job_posting, target_url: "https://example.com/apply") }

  describe ".call" do
    it "attempts to auto-fill an application form" do
      mock_playwright = double("Playwright")
      mock_browser = double("Browser")
      mock_page = double("Page")
      mock_element = double("Element")
      mock_chromium = double("Chromium")

      expect(Playwright).to receive(:create).and_yield(mock_playwright)
      allow(mock_playwright).to receive(:chromium).and_return(mock_chromium)
      expect(mock_chromium).to receive(:launch).and_yield(mock_browser)
      expect(mock_browser).to receive(:new_page).and_return(mock_page)

      expect(mock_page).to receive(:goto).with(job_posting.target_url)
      expect(mock_page).to receive(:query_selector).with(anything).at_least(:once).and_return(mock_element)
      expect(mock_element).to receive(:click)
      expect(mock_page).to receive(:wait_for_load_state).with(state: "networkidle")

      # Mock auto-fill
      allow(mock_page).to receive(:fill)

      result = described_class.call(job_posting, user)
      expect(result[:success]).to be true
    end
  end
end
