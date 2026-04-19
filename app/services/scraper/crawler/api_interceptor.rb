# frozen_string_literal: true

module Scraper
  module Crawler
    class ApiInterceptor
      def initialize(page)
        @page = page
        @api_calls = []
      end

      def start_capturing
        @page.on('response') do |response|
          if response.request.resource_type == 'fetch' || response.request.resource_type == 'xhr'
            @api_calls << {
              url: response.url,
              status: response.status,
              headers: response.headers
            }
          end
        end
      end

      def captured_calls
        @api_calls
      end
    end
  end
end
