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

  # Cheap, literal keyword matching -- not an ML classifier, same tradeoff as
  # BANNED_TITLES above. Broad terms ("Sales", "Marketing") deliberately
  # cast a wide net -- live-verified against real dev data, where phrase-only
  # matching ("Account Executive" etc.) missed common real titles like "Loan
  # Sales Specialist"/"Sales Associate". ENGINEERING_ADJACENT_EXCEPTIONS
  # protects genuinely technical hybrid roles ("Sales Engineer") from being
  # caught by the broad "Sales" match. Runs before JobBoards::AnalysisJob
  # (Categorizer + Embedder) ever gets a chance to enqueue -- see
  # Syncer#enrich_if_needed, which skips it once a posting is ignored.
  NON_ENGINEERING_TITLE_KEYWORDS = [
    "Sales", "Account Executive", "Business Development Representative",
    "Customer Support", "Customer Success", "Customer Service",
    "UI Designer", "UX Designer", "UI/UX Designer", "Graphic Designer", "Visual Designer",
    "Marketing", "Recruiter", "Talent Acquisition"
  ].freeze

  ENGINEERING_ADJACENT_EXCEPTIONS = [
    "Sales Engineer", "Sales Engineering", "Solutions Engineer", "Solutions Engineering"
  ].freeze

  def initialize(job_posting, user: nil)
    @job_posting = job_posting
    @user = user || User.first # Default to the primary user
  end

  def useful?
    return false unless valid_title?
    return false if country_mismatch? || excluded_source?
    return false if body_too_short?
    return false if non_engineering_title?

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

  def non_engineering_title?
    return false if engineering_adjacent_exception?

    NON_ENGINEERING_TITLE_KEYWORDS.any? { |keyword| title_includes?(keyword) }
  end

  def engineering_adjacent_exception?
    ENGINEERING_ADJACENT_EXCEPTIONS.any? { |keyword| title_includes?(keyword) }
  end

  def title_includes?(keyword)
    @job_posting.title.downcase.include?(keyword.downcase)
  end

  # Geographic Shield: only keep jobs in the user's preferred countries.
  def country_mismatch?
    return false if @job_posting.country_code.blank? || @user.preferred_countries.blank?

    @user.preferred_countries.exclude?(@job_posting.country_code)
  end

  def body_too_short?
    @job_posting.body.blank? || @job_posting.body.length < 50
  end

  # source (raw ingestion-event record) -> origin (Origin, a plain name
  # holder) -> matched by name to JobBoards::Source (the "board", e.g.
  # Arbeitnow -- flagged via /admin/sources/:id). There's no direct FK
  # between Origin and JobBoards::Source; name is the only link the syncer
  # establishes (JobBoards::Syncer#resolve_dashboard_source). Flagging keeps
  # the board ingesting for future analysis while its postings stay out of
  # every result list, the same auto-ignore path CompanyResolver uses for
  # Company#ingestion_enabled.
  def excluded_source?
    origin_name = @job_posting.source&.origin&.name
    return false if origin_name.blank?

    JobBoards::Source.find_by(name: origin_name)&.excluded_from_results? || false
  end
end
