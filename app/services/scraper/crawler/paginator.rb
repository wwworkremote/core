# frozen_string_literal: true

class Scraper::Crawler::Paginator
  def initialize(browser_context, next_page_selector)
    @browser = browser_context
    @selector = next_page_selector
  end

  def next_page?
    @browser.has_selector?(@selector)
  end

  def click_next
    @browser.click(@selector)
  end
end
