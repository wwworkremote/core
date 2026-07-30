# frozen_string_literal: true

class EmailIngestion::SourceClassifier
  DOMAIN_SOURCES = { "indeed.com" => "indeed", "linkedin.com" => "linkedin", "adzuna.com" => "adzuna" }.freeze
  SUBJECT_SOURCES = { "Indeed" => "indeed", "LinkedIn" => "linkedin", "Adzuna" => "adzuna" }.freeze

  def initialize(parsed_email)
    @parsed_email = parsed_email
  end

  def call
    source_from_domain || source_from_subject || "unknown"
  end

  private

  def source_from_domain
    DOMAIN_SOURCES.find { |domain, _| from_domain?(domain) }&.last
  end

  # Fallback to subject line analysis
  def source_from_subject
    SUBJECT_SOURCES.find { |text, _| subject_contains?(text) }&.last
  end

  def from_domain?(domain)
    @parsed_email[:from]&.downcase&.include?(domain)
  end

  def subject_contains?(text)
    @parsed_email[:subject]&.include?(text)
  end
end
