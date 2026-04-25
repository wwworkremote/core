# frozen_string_literal: true

class EmailIngestion::SourceClassifier
  def initialize(parsed_email)
    @parsed_email = parsed_email
  end

  def call
    return 'indeed' if from_domain?('indeed.com')
    return 'linkedin' if from_domain?('linkedin.com')
    return 'adzuna' if from_domain?('adzuna.com')


    # Fallback to subject line analysis

    return 'indeed' if subject_contains?('Indeed')
    return 'linkedin' if subject_contains?('LinkedIn')
    return 'adzuna' if subject_contains?('Adzuna')

    'unknown'
  end

  private

  def from_domain?(domain)
    @parsed_email[:from]&.downcase&.include?(domain)
  end

  def subject_contains?(text)
    @parsed_email[:subject]&.include?(text)
  end
end
