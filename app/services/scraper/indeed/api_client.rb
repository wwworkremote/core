# frozen_string_literal: true

module Scraper
  module Indeed
    class ApiClient
      # Based on intercepted traffic patterns
      BASE_URL = "https://www.indeed.com/api/v1/jobs"

      def self.search(query, location: 'Remote')
        new.search(query, location)
      end

      def search(query, location)
        params = {
          q: query,
          l: location,
          format: 'json',
          from: 'js'
        }
        
        response = Faraday.get(BASE_URL, params) do |req|
          req.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        end

        if response.success?
          JSON.parse(response.body)
        else
          Rails.logger.error "[Indeed::ApiClient] Search failed: #{response.status}"
          nil
        end
      end
    end
  end
end
