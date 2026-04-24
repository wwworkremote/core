# frozen_string_literal: true

module JobBoards
  class QualityFilter
    BANNED_TITLES = [
      '/JOB_POSTINGS',
      '/JOBS',
      'Sign In',
      'Log In',
      'Navigation',
      'Menu',
      'Job Search'
    ].freeze

    BANNED_KEYWORDS = [
      'no visa sponsorship',
      'must be authorized to work in',
      'us citizens only',
      'us only',
      'uk only'
    ].freeze

    def initialize(job_posting, user: nil)
      @job_posting = job_posting
      @user = user || User.first # Default to the primary user
    end

    def useful?
      return false if @job_posting.title.blank?
      return false if BANNED_TITLES.any? { |banned| @job_posting.title.upcase == banned.upcase }
      return false if @job_posting.title.length < 3
      
      # Geographic Shield: Only keep jobs in preferred countries
      if @job_posting.country_code.present? && @user.preferred_countries.present?
        return false unless @user.preferred_countries.include?(@job_posting.country_code)
      end

      # Seniority Check: Filter out Junior/Intern if user is Senior/Staff
      # (This assumes we have profile data, but for now we can do basic string matches)
      if @job_posting.title.match?(/junior|intern|associate/i)
        # return false if user_is_senior?
      end

      # Eligibility Check: Search for "US only" or "UK only" in body if mismatch
      if @job_posting.body.present?
        # Logic here to detect high-certainty exclusion text
      end

      # If body is extremely short and it's from a known "noisy" source, it might be junk
      return false if @job_posting.body.blank? || @job_posting.body.length < 50
      
      true
    end
  end
end
