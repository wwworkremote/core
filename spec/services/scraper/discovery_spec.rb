# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scraper::Crawler::Discovery do
  let(:board_name) { 'Cord' }
  let(:base_url) { 'https://cord.com/jobs' }
  let(:selector) { 'a.job-link' }

  describe '#call' do
    it 'discovers and persists links' do
      mock_playwright = double('Playwright')
      mock_browser = double('Browser')
      mock_page = double('Page')
      mock_chromium = double('Chromium')

      expect(Playwright).to receive(:create).and_yield(mock_playwright)
      allow(mock_playwright).to receive(:chromium).and_return(mock_chromium)
      expect(mock_chromium).to receive(:launch).and_yield(mock_browser)
      expect(mock_browser).to receive(:new_page).and_return(mock_page)

      expect(mock_page).to receive(:goto).with(base_url)
      expect(mock_page).to receive(:wait_for_load_state).with(state: 'networkidle')

      mock_links = ['https://cord.com/jobs/1', 'https://cord.com/jobs/2']
      expect(mock_page).to receive(:eval_on_selector_all).with(selector, anything).and_return(mock_links)

      expect {
        described_class.new(board_name, base_url, selector: selector).call
      }.to change(DiscoveryLink, :count).by(2)

      expect(DiscoveryLink.last.url).to eq('https://cord.com/jobs/2')
    end
  end
end
