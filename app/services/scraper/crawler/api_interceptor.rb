# frozen_string_literal: true

class Scraper::Crawler::ApiInterceptor
  def initialize(page)
    @page = page
    @api_calls = []
  end

  def start_capturing
    @page.on('response', lambda { |response|
      if %w[fetch xhr].include?(response.request.resource_type)
        @api_calls << {
          url: response.url,
          status: response.status,
          headers: response.headers
        }
      end
    })
  end

  def captured_calls
    @api_calls
  end
end
