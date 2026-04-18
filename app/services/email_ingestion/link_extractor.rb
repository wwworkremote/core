# frozen_string_literal: true

require 'uri'
require 'nokogiri'

module EmailIngestion
  class LinkExtractor
    # Regex to identify potential job links based on provider
    # Indeed: https://www.indeed.com/rc/clk?jk=... or https://www.indeed.com/job/...
    # LinkedIn: https://www.linkedin.com/jobs/view/... or https://www.linkedin.com/comm/jobs/view/...
    # Adzuna: https://www.adzuna.com/details/...

    JOB_LINK_PATTERNS = {
      'indeed' => /indeed\.com\/(rc\/clk|job|jobs|viewjob)/i,
      'linkedin' => /linkedin\.com\/(jobs\/view|comm\/jobs\/view)/i,
      'adzuna' => /adzuna\.com\/details/i
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
      /linkedin\.com\/company/i,
      /linkedin\.com\/in\//i
    ].freeze

    def initialize(parsed_email, source_provider)
      @parsed_email = parsed_email
      @source_provider = source_provider
    end

    def call
      urls = []

      # Extract from text body
      if @parsed_email[:text_body]
        urls += URI.extract(@parsed_email[:text_body], %w[http https])
      end

      # Extract from HTML body
      if @parsed_email[:html_body]
        doc = Nokogiri::HTML(@parsed_email[:html_body])
        urls += doc.css('a').map { |a| a['href'] }.compact
      end

      clean_urls(urls)
    end

    private

    def clean_urls(urls)
      urls.map do |url|
        begin
          uri = URI.parse(url.to_s.strip)
          next unless %w[http https].include?(uri.scheme)

          # Remove fragments
          uri.fragment = nil

          # Special handling for tracked/redirect links if we can identify them
          # For now, just normalize the URL string
          uri.to_s
        rescue URI::InvalidURIError
          nil
        end
      end.compact.uniq.select { |url| candidate_job_link?(url) }
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
end
