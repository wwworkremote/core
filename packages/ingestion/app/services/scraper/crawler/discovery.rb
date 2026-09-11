# frozen_string_literal: true

require "playwright"

class Scraper::Crawler::Discovery
  LINK_MATCHERS = {
    "cord" => ->(url) { url.include?("/jobs/") && url =~ /\d+/ },
    "linkedin" => ->(url) { url.include?("/jobs/view/") },
    "indeed" => ->(url) { url.include?("/rc/clk") || url.include?("/viewjob?jk=") },
    "dice" => ->(url) { url.include?("/job-detail/") || url.include?("dice.com/job-detail") },
    "glassdoor" => lambda { |url|
      url.include?("/job-listing/") || url.include?("jl=") || url.include?("glassdoor.com/job-listing")
    }
  }.freeze
  DEFAULT_MATCHER = ->(url) { url.include?("/job") }

  def initialize(board_name, base_url, selector: 'a[href*="/job/"]')
    @board_name = board_name
    @base_url = base_url
    @selector = selector
  end

  def call
    launch_and_discover
  rescue Playwright::Error => e
    log_playwright_error(e)
  rescue StandardError => e
    log_unexpected_error(e)
  end

  private

  def launch_and_discover
    Playwright.create(playwright_cli_executable_path: playwright_executable_path) do |playwright|
      playwright.chromium.launch(headless: true) { |browser| discover_and_save(browser) }
    end
  end

  def playwright_executable_path
    Rails.root.join("node_modules/.bin/playwright").to_s
  end

  def discover_and_save(browser)
    save_links(discover_links(new_page(browser)))
  end

  def new_page(browser)
    page = browser.new_page
    page.default_timeout = 30_000 # 30 seconds
    page.goto(@base_url, waitUntil: "domcontentloaded")
    page.wait_for_load_state(state: "networkidle")
    page
  end

  def discover_links(page)
    all_links = page.eval_on_selector_all(@selector, "elements => elements.map(el => el.href)")
    filter_links(all_links).uniq
  end

  def save_links(job_links)
    job_links.each do |url|
      DiscoveryLink.find_or_create_by!(board_name: @board_name, url: url) { |link| link.status = "pending" }
    end
  end

  def filter_links(all_links)
    matcher = LINK_MATCHERS.fetch(@board_name.downcase, DEFAULT_MATCHER)
    all_links.select { |url| matcher.call(url) }
  end

  def log_playwright_error(error)
    Rails.logger.error "[Crawler::Discovery] Playwright error for #{@board_name} at #{@base_url}: #{error.message}"
  end

  def log_unexpected_error(error)
    Rails.logger.error "[Crawler::Discovery] Unexpected error for #{@board_name}: #{error.message}"
  end
end
