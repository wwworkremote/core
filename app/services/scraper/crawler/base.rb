# frozen_string_literal: true

module Scraper
  module Crawler
    class Base
      def initialize(board_name, start_url)
        @board_name = board_name
        @start_url = start_url
      end

      def call
        # Playwright navigation to find links
        playwright_path = Rails.root.join('node_modules/.bin/playwright').to_s
        Playwright.create(playwright_cli_executable_path: playwright_path) do |playwright|
          playwright.chromium.launch(headless: true) do |browser|
            page = browser.new_page
            page.goto(@start_url)

            # Logic: Extract all links, filter by job board patterns
            links = page.eval_on_selector_all('a[href*="/job/"]', 'elements => elements.map(el => el.href)')

            links.each do |url|
              DiscoveryLink.find_or_create_by!(board_name: @board_name, url: url) do |link|
                link.status = 'pending'
              end
            end
          end
        end
      end
    end
  end
end
