# frozen_string_literal: true

class JobBoards::QualityFilter
  BANNED_TITLES = [
    "/JOB_POSTINGS",
    "/JOBS",
    "Sign In",
    "Log In",
    "Navigation",
    "Menu",
    "Job Search"
  ].freeze

  BANNED_KEYWORDS = [
    "no visa sponsorship",
    "must be authorized to work in",
    "us citizens only",
    "us only",
    "uk only"
  ].freeze

  def initialize(job_posting, user: nil)
    @job_posting = job_posting
    @user = user || User.first # Default to the primary user
  end

  def useful?
    return false unless valid_title?
    return false if country_mismatch?
    return false if body_too_short?

    true
  end

  private

  def valid_title?
    return false if @job_posting.title.blank?
    return false if banned_title?

    @job_posting.title.length >= 3
  end

  def banned_title?
    BANNED_TITLES.any? { |banned| @job_posting.title.upcase == banned.upcase }
  end

  # Geographic Shield: only keep jobs in the user's preferred countries.
  def country_mismatch?
    return false if @job_posting.country_code.blank? || @user.preferred_countries.blank?

    @user.preferred_countries.exclude?(@job_posting.country_code)
  end

  def body_too_short?
    @job_posting.body.blank? || @job_posting.body.length < 50
  end
end
