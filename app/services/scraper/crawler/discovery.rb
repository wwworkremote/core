# frozen_string_literal: true

module Scraper
  module Crawler
    class Discovery
      def initialize(board_name, base_url, selector: 'a[href*="/job/"]')
        @board_name = board_name
        @base_url = base_url
        @selector = selector
      end

      def call
        # Initialize Playwright/HTTP client
        browser = Playwright.create(headless: true)
        page = browser.new_page
        page.goto(@base_url)
        
        # Discover links
        links = page.eval_on_selector_all(@selector, 'elements => elements.map(el => el.href)')
        
        links.uniq.each do |url|
          DiscoveryLink.find_or_create_by!(board_name: @board_name, url: url) do |link|
            link.status = 'pending'
          end
        end
        browser.close
      end
    end
  end
end
