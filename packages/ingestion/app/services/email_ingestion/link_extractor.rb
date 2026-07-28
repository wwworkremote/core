# frozen_string_literal: true

require "uri"
require "nokogiri"

class EmailIngestion::LinkExtractor
  # Regex to identify potential job links based on provider
  # Indeed: https://www.indeed.com/rc/clk?jk=... or https://www.indeed.com/job/...
  # LinkedIn: https://www.linkedin.com/jobs/view/... or https://www.linkedin.com/comm/jobs/view/...
  # Adzuna: https://www.adzuna.com/details/...

  JOB_LINK_PATTERNS = {
    "indeed" => %r{indeed\.com/(rc/clk|job|jobs|viewjob)}i,
    "linkedin" => %r{linkedin\.com/(jobs/view|comm/jobs/view)}i,
    "adzuna" => %r{adzuna\.com/details}i
  }.freeze

  NOISE_PATTERNS = [
    /unsubscribe/i,
    /preferences/i,
    /help/i,
    /privacy/i,
    /terms/i,
    /settings/i,
    /fb\.com/i,
    /twitter\.com/i,
    /instagram\.com/i,
    %r{linkedin\.com/company}i,
    %r{linkedin\.com/in/}i
  ].freeze

  def initialize(parsed_email, source_provider)
    @parsed_email = parsed_email
    @source_provider = source_provider
  end

  def call
    clean_urls(text_body_urls + html_body_urls)
  end

  private

  def text_body_urls
    return [] unless @parsed_email[:text_body]

    URI.extract(@parsed_email[:text_body], %w[http https])
  end

  def html_body_urls
    return [] unless @parsed_email[:html_body]

    Nokogiri::HTML(@parsed_email[:html_body]).css("a").filter_map { |a| a["href"] }
  end

  def clean_urls(urls)
    normalized = urls.filter_map { |url| normalize_url(url) }
    normalized.uniq.select { |url| candidate_job_link?(url) }
  end

  # Strips fragments and normalizes the string. Special handling for
  # tracked/redirect links could go here if we can identify them.
  def normalize_url(url)
    parse_http_uri(url)&.tap { |uri| uri.fragment = nil }&.to_s
  end

  def parse_http_uri(url)
    uri = URI.parse(url.to_s.strip)
    uri if %w[http https].include?(uri.scheme)
  rescue URI::InvalidURIError
    nil
  end

  def candidate_job_link?(url)
    return false if NOISE_PATTERNS.any? { |p| url =~ p }

    pattern = JOB_LINK_PATTERNS[@source_provider]
    return url =~ pattern if pattern

    # Fallback: if we don't know the provider's specific pattern,
    # but it's not noise, we could include it, but the prompt
    # implies we know the source provider.
    false
  end
end
