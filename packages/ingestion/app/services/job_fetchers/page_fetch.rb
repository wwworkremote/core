# frozen_string_literal: true

require "playwright"

class JobFetchers::PageFetch
  USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
               "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

  def initialize(url)
    @url = url
  end

  def call
    # Tier 1: Faraday (Static HTML)
    response = fetch_static
    return static_result(response) if response && content_seems_legit?(response.body)

    # Tier 2: Playwright (Dynamic/Blocked)
    fetch_with_playwright
  end

  private

  def static_result(response)
    { content: response.body, final_url: @url, fetch_mode: "static" }
  end

  def fetch_static
    Faraday.get(@url) { |req| req.headers["User-Agent"] = USER_AGENT }
  rescue StandardError => e
    Rails.logger.error "[PageFetch] Static fetch error for #{@url}: #{e.message}"
    nil
  end

  def content_seems_legit?(body)
    return false if body.blank?
    # Heuristic: check if it's just a "Checking your browser" or "Access Denied" page
    return false if body =~ /Checking your browser/i || body =~ /Access Denied/i || body =~ /Cloudflare/i
    # Should have some significant content
    body.length > 2000
  end

  def fetch_with_playwright
    launch_browser { |browser| render_page(browser) }
  rescue StandardError => e
    log_playwright_error(e)
    nil
  end

  def launch_browser(&)
    playwright_path = Rails.root.join("node_modules/.bin/playwright").to_s
    Playwright.create(playwright_cli_executable_path: playwright_path) do |playwright|
      playwright.chromium.launch(headless: true, &)
    end
  end

  def render_page(browser)
    page = browser.new_context(userAgent: USER_AGENT).new_page
    interceptor = start_intercepting(page)
    navigate(page)

    { content: page.content, final_url: page.url, fetch_mode: "playwright", api_calls: interceptor.captured_calls }
  end

  def navigate(page)
    page.goto(@url, waitUntil: "domcontentloaded")
    sleep 10 # Allow some time for background requests to settle
    wait_for_content(page)
  end

  # Optional: Intercept API calls if needed for specific providers
  def start_intercepting(page)
    Scraper::Crawler::ApiInterceptor.new(page).tap(&:start_capturing)
  end

  def wait_for_content(page)
    page.wait_for_selector('h1, h2, .job-title, [class*="title"]', timeout: 10_000)
  rescue Playwright::TimeoutError
    # Just continue if selector not found
  end

  def log_playwright_error(error)
    Rails.logger.error "[PageFetch] Playwright fetch error for #{@url}: #{error.message}\n" \
                       "#{error.backtrace.first(10).join("\n")}"
  end
end
