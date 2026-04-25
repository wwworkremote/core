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

    if response && content_seems_legit?(response.body)
      return {
        content: response.body,
        final_url: @url,
        fetch_mode: "static"
      }
    end

    # Tier 2: Playwright (Dynamic/Blocked)
    fetch_with_playwright
  end

  private

  def fetch_static
    Faraday.get(@url) do |req|
      req.headers["User-Agent"] = USER_AGENT
    end
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
    playwright_path = Rails.root.join("node_modules/.bin/playwright").to_s
    Playwright.create(playwright_cli_executable_path: playwright_path) do |playwright|
      playwright.chromium.launch(headless: true) do |browser|
        context = browser.new_context(userAgent: USER_AGENT)
        page = context.new_page

        # Optional: Intercept API calls if needed for specific providers
        interceptor = Scraper::Crawler::ApiInterceptor.new(page)
        interceptor.start_capturing

        page.goto(@url, waitUntil: "domcontentloaded")
        sleep 10 # Allow some time for background requests to settle

        # Wait for meaningful content
        begin
          page.wait_for_selector('h1, h2, .job-title, [class*="title"]', timeout: 10_000)
        rescue Playwright::TimeoutError
          # Just continue if selector not found
        end

        {
          content: page.content,
          final_url: page.url,
          fetch_mode: "playwright",
          api_calls: interceptor.captured_calls
        }
      end
    end
  rescue StandardError => e
    Rails.logger.error "[PageFetch] Playwright fetch error for #{@url}: #{e.message}\n" \
                       "#{e.backtrace.first(10).join("\n")}"
    nil
  end
end
