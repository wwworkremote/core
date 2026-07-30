# frozen_string_literal: true

module JobPostingsHelper
  def safe_job_url(url)
    return "#" if url.blank?

    valid_job_url?(url) ? url : "#"
  end

  private

  def valid_job_url?(url)
    %w[http https].include?(URI.parse(url).scheme)
  rescue URI::InvalidURIError
    false
  end
end
