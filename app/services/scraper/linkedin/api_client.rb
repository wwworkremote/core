# frozen_string_literal: true

module Scraper
  module LinkedIn
    class ApiClient
      # Based on intercepted patterns for public search
      BASE_URL = "https://www.linkedin.com/jobs-guest/jobs/api/seeMoreJobPostings/search"

      def self.search(keywords, location: 'United States', remote: true)
        new.search(keywords, location, remote)
      end

      def search(keywords, location, remote)
        params = {
          keywords: keywords,
          location: location,
          start: 0
        }
        params[:f_WT] = 2 if remote

        response = Faraday.get(BASE_URL, params) do |req|
          req.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        end

        if response.success?
          # This specifically returns HTML fragments of job cards
          response.body
        else
          Rails.logger.error "[LinkedIn::ApiClient] Search failed: #{response.status}"
          nil
        end
      end
    end
  end
end
