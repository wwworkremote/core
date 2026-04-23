# frozen_string_literal: true

require 'playwright'

module Scraper
  module Crawler
    class Discovery
      def initialize(board_name, base_url, selector: 'a[href*="/job/"]')
        @board_name = board_name
        @base_url = base_url
        @selector = selector
      end

      def call
        Playwright.create(playwright_cli_executable_path: Rails.root.join('node_modules/.bin/playwright').to_s) do |playwright|
          playwright.chromium.launch(headless: true) do |browser|
            page = browser.new_page
            page.goto(@base_url)
            page.wait_for_load_state(state: 'networkidle')

            # Discover links
            all_links = page.eval_on_selector_all(@selector, 'elements => elements.map(el => el.href)')

            # Filter links based on board-specific patterns to ensure we only get job details
            job_links = all_links.select do |url|
              case @board_name.downcase
              when 'cord' then url.include?('/jobs/') && url =~ /\d+/
              when 'linkedin' then url.include?('/jobs/view/')
              when 'indeed' then url.include?('/rc/clk') || url.include?('/viewjob?jk=')
              when 'dice' then url.include?('/job-detail/') || url.include?('dice.com/job-detail')
              when 'glassdoor' then url.include?('/job-listing/') || url.include?('jl=') || url.include?('glassdoor.com/job-listing')
              else url.include?('/job')
              end
            end

            job_links.uniq.each do |url|
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
