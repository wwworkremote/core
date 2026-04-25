# frozen_string_literal: true

require 'faraday'
require 'uri'

class EmailIngestion::CanonicalUrlResolver
  def initialize(url)
    @url = url
  end

  def call
    resolved_url = @url

    # Try following redirects for a few steps
    5.times do
      response = Faraday.get(resolved_url) do |req|
        req.headers['User-Agent'] =
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      end

      break unless [301, 302, 303, 307, 308].include?(response.status)
      location = response.headers['location']
      break unless location
      # Resolve relative URLs
      resolved_url = URI.join(resolved_url, location).to_s
    rescue StandardError => e
      Rails.logger.error "[CanonicalUrlResolver] Error resolving #{@url}: #{e.message}"
      break
    end

    # Strip tracking params from final URL if we can
    strip_tracking_params(resolved_url)
  end

  private

  def strip_tracking_params(url)
    uri = URI.parse(url)
    return url unless uri.query

    params = Rack::Utils.parse_nested_query(uri.query)
    # Common tracking params to strip
    %w[utm_source utm_medium utm_campaign utm_term utm_content ref itm_source itm_medium itm_campaign qre itm_content
       qre src].each do |p|
      params.delete(p)
    end

    uri.query = params.any? ? Rack::Utils.build_query(params) : nil
    uri.to_s
  rescue URI::InvalidURIError
    url
  end
end
