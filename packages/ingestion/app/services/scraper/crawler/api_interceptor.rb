# frozen_string_literal: true

class Scraper::Crawler::ApiInterceptor
  def initialize(page)
    @page = page
    @api_calls = []
  end

  def start_capturing
    @page.on("response", method(:capture_api_response))
  end

  def captured_calls
    @api_calls
  end

  private

  def capture_api_response(response)
    return unless %w[fetch xhr].include?(response.request.resource_type)

    @api_calls << { url: response.url, status: response.status, headers: response.headers }
  end
end
