# frozen_string_literal: true

# Resolves the markdown job description for Api::JobPostingsController#enrich:
# prefers the user-reviewed text/HTML sent by the browser extension panel,
# falling back to re-running CanonicalJobExtractor on the raw HTML snapshot.
class JobPostingEnrichment::DescriptionResolver
  PROVIDER_DOMAINS = {
    "linkedin.com" => "linkedin",
    "indeed.com" => "indeed",
    "adzuna.com" => "adzuna",
    "greenhouse.io" => "greenhouse",
    "lever.co" => "lever",
    "workday.com" => "workday",
    "myworkdayjobs.com" => "workday",
    "ashby.com" => "ashby",
    "ashbyhq.com" => "ashby",
    "smartrecruiters.com" => "smartrecruiters",
    "wellfound.com" => "wellfound",
    "weworkremotely.com" => "weworkremotely",
    "remoteok.com" => "remoteok"
  }.freeze

  attr_reader :provider

  def self.call(...)
    new(...).call
  end

  def initialize(extracted:, html:, url:, provider: nil)
    @extracted = extracted
    @html = html
    @url = url
    @provider = provider.presence || detect_provider(url.to_s)
  end

  def call
    return reviewed_markdown_body if @extracted["description_text"].present?

    extracted_markdown_body
  end

  private

  def reviewed_markdown_body
    to_markdown(@extracted["description_html"].presence || @extracted["description_text"])
  end

  def extracted_markdown_body
    job_data = canonical_job_data
    return nil if job_data.blank? || job_data[:description].blank?

    to_markdown(job_data[:description])
  end

  def canonical_job_data
    JobFetchers::CanonicalJobExtractor.new(@html, @url, provider).call
  end

  def to_markdown(source)
    ReverseMarkdown.convert(source, unknown_tags: :bypass, github_flavored: true).strip
  end

  # Use the provider string sent by the extension directly; only fall back to
  # URL detection for legacy callers that do not send the field.
  def detect_provider(url)
    url_lower = url.downcase
    PROVIDER_DOMAINS.find { |domain, _| url_lower.include?(domain) }&.last || "generic"
  end
end
