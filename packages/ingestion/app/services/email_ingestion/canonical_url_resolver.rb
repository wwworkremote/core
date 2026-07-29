# frozen_string_literal: true

require "faraday"
require "uri"

class EmailIngestion::CanonicalUrlResolver
  USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
               "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

  REDIRECT_STATUSES = [301, 302, 303, 307, 308].freeze

  TRACKING_PARAMS = %w[
    utm_source utm_medium utm_campaign utm_term utm_content ref itm_source itm_medium
    itm_campaign qre itm_content qre src
  ].freeze

  def initialize(url)
    @url = url
  end

  def call
    strip_tracking_params(resolve_redirects)
  end

  private

  def resolve_redirects
    resolved_url = @url
    5.times { resolved_url = follow_redirect(resolved_url) || break }
    resolved_url
  end

  def follow_redirect(url)
    location = redirect_location(url)
    location && URI.join(url, location).to_s
  rescue StandardError => e
    log_error(e)
    nil
  end

  def redirect_location(url)
    response = fetch(url)
    return nil unless REDIRECT_STATUSES.include?(response.status)

    response.headers["location"]
  end

  def log_error(error)
    Rails.logger.error "[CanonicalUrlResolver] Error resolving #{@url}: #{error.message}"
  end

  def fetch(url)
    Faraday.get(url) { |req| req.headers["User-Agent"] = USER_AGENT }
  end

  def strip_tracking_params(url)
    uri = URI.parse(url)
    return url unless uri.query

    uri.tap { |u| u.query = cleaned_query(u.query) }.to_s
  rescue URI::InvalidURIError
    url
  end

  def cleaned_query(query)
    params = Rack::Utils.parse_nested_query(query)
    TRACKING_PARAMS.each { |p| params.delete(p) }
    params.any? ? Rack::Utils.build_query(params) : nil
  end
end
