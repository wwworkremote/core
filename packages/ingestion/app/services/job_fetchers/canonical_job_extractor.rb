# frozen_string_literal: true

require "nokogiri"

class JobFetchers::CanonicalJobExtractor
  # Signatures of bot-check/interstitial pages we've actually been served instead
  # of a real job posting (confirmed via 54 fake JobPosting rows -- 51x "We're
  # signing you in", 3x "Additional Verification Required" -- all from Indeed
  # email links, TASK-26). The extractor has no way to tell "the page really is
  # titled this" from "we got challenged", so this is necessarily a denylist of
  # observed + common interstitial copy, not a general solution.
  INTERSTITIAL_TITLE_PATTERNS = [
    /signing you in/i,
    /additional verification required/i,
    /verify you'?re? a human/i,
    /checking your browser/i,
    /just a moment/i,
    /attention required/i,
    /access denied/i,
    /are you a robot/i
  ].freeze

  def initialize(html, url, provider)
    @doc = Nokogiri::HTML(html)
    @url = url
    @provider = provider
  end

  # Returns nil (instead of the usual hash) when the page looks like a bot
  # wall rather than real content, so callers can treat the fetch as failed.
  def call
    result = extract
    return nil if interstitial?(result)

    result
  end

  private

  def extract
    config = Selectors::FIELD_SELECTORS[@provider] || Selectors::GENERIC_SELECTORS
    extract_fields(config).merge(url: @url)
  end

  def extract_fields(config)
    fields = %i[title company location].index_with { |key| extract_field(config[key]) }
    fields[:description] = extract_html_field(config[:description])
    fields
  end

  def extract_field(selector)
    return nil if selector.nil?
    return send(selector) if selector.is_a?(Symbol)

    first_present(selector) { |nodes| nodes.first&.text&.strip }
  end

  def extract_html_field(selector)
    return nil if selector.nil?

    first_present(selector, &:inner_html)
  end

  def first_present(selectors)
    Array(selectors).each do |selector|
      value = yield(@doc.css(selector))
      return value if value.present?
    end
    nil
  end

  def indeed_location
    @doc.css(".jobsearch-JobInfoHeader-subtitle div").last&.text&.strip
  end

  def static_remote
    "Remote"
  end

  def interstitial?(result)
    title = result[:title].to_s
    INTERSTITIAL_TITLE_PATTERNS.any? { |pattern| title.match?(pattern) }
  end
end
