# frozen_string_literal: true

module JobPostingsHelper
  def safe_job_url(url)
    return '#' if url.blank?

    uri = URI.parse(url)
    return '#' unless %w[http https].include?(uri.scheme)

    url
  rescue URI::InvalidURIError
    '#'
  end
end
