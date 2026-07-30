# frozen_string_literal: true

class Scraper::Crawler::Base
  def initialize(board_name, start_url)
    @board_name = board_name
    @start_url = start_url
  end

  def call
    playwright_path = Rails.root.join("node_modules/.bin/playwright").to_s
    Playwright.create(playwright_cli_executable_path: playwright_path) do |playwright|
      playwright.chromium.launch(headless: true) { |browser| discover_links(browser) }
    end
  end

  private

  def discover_links(browser)
    page = browser.new_page
    page.goto(@start_url)
    extract_job_links(page).each { |url| store_link(url) }
  end

  # Extract all links, filter by job board patterns
  def extract_job_links(page)
    page.eval_on_selector_all('a[href*="/job/"]', "elements => elements.map(el => el.href)")
  end

  def store_link(url)
    DiscoveryLink.find_or_create_by!(board_name: @board_name, url: url) do |link|
      link.status = "pending"
    end
  end
end
