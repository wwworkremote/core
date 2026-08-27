# frozen_string_literal: true

# Shared upsert-and-advance skeleton for backfilling application history
# (TASK-83 AC #9). Every provider (LinkedIn, Greenhouse, Indeed) previously
# reimplemented the same find-or-create-posting, resolve-a-Source,
# advance-the-tracked-record sequence with its own row shape; this is that
# sequence once, with each provider supplying only what actually differs:
# how to read its own row.
#
# Subclasses MUST implement: #source_name, #signature, #native_id_fragment,
# #target_url, #company, #title, #applied_at_from(row).
# Subclasses MAY override: #location, #status_event, #outcome_for(row),
# #outcome_source_for(row), #overwrite_applied_at?.
# rubocop:disable-next Metrics/ClassLength -- one cohesive template-method
# skeleton; splitting it would obscure the sequence, not simplify it.
class Applications::RowImporter
  def self.call(row, user:)
    new(row, user).call
  end

  def initialize(row, user)
    @row = row
    @user = user
  end

  def call
    posting = upsert_posting
    applied_at = applied_at_from(@row)
    advance(posting, applied_at)
    { posting: posting, applied_at: applied_at, outcome: outcome_for(@row) }
  end

  private

  def source_name
    raise NotImplementedError
  end

  def signature
    raise NotImplementedError
  end

  def native_id_fragment
    raise NotImplementedError
  end

  def target_url
    raise NotImplementedError
  end

  def company
    raise NotImplementedError
  end

  def title
    raise NotImplementedError
  end

  def applied_at_from(_row)
    raise NotImplementedError
  end

  def location
    nil
  end

  # "apply" (default) or "favorite" -- LinkedIn's tracker distinguishes an
  # application from a click-through it can't confirm was finished.
  def status_event
    "apply"
  end

  def outcome_for(_row)
    nil
  end

  def outcome_source_for(_row)
    "employer"
  end

  # false (fill-only) by default: a source whose date is an approximation
  # (LinkedIn's relative ages) must never clobber an exact date another
  # source already wrote. A provider with an exact, authoritative
  # timestamp (Greenhouse) overrides this to true.
  def overwrite_applied_at?
    false
  end

  # true (overwrite) by default -- matches every provider except LinkedIn,
  # whose only signal ("listing closed") is weaker than an employer's
  # explicit rejection and must never replace one already recorded.
  def outcome_overwrite?
    true
  end

  def upsert_posting
    posting = find_posting
    posting ? backfill(posting) : create_posting
  end

  def find_posting
    Applications::PostingMatcher.call(signature: signature, native_id_fragment: native_id_fragment,
                                      target_url: target_url, company: company, title: title)
  end

  def create_posting
    JobPosting.create!(new_posting_attrs)
  end

  def new_posting_attrs
    { signature: signature, title: title.to_s.strip, company_name: company.to_s.strip, location: location,
      source_id: source_id, target_url: target_url, status: "none", crawl_status: "pending" }
  end

  # A row's company may fill in what an earlier, thinner source (e.g. an
  # email-scraped listing) left blank -- never overwrites one already set.
  def backfill(posting)
    posting.update!(company_name: company.to_s.strip) if posting.company_name.blank? && company.present?
    posting
  end

  def source_id
    origin = Origin.find_or_create_by!(name: source_name)
    Source.find_or_create_by!(signature: "#{source_name.downcase}-app-import") do |s|
      s.origin = origin
      s.name = source_name
    end.id
  end

  # UserJobPosting owns pipeline state entirely as of TASK-82 phase 3 --
  # JobPosting has no favorite!/apply! of its own to call.
  def advance(posting, applied_at)
    tracked = @user.user_job_postings.find_or_create_by!(job_posting: posting)
    tracked.record_status_event!(status_event) if tracked.status != target_status
    apply_dates(tracked, applied_at)
    apply_outcome(tracked)
    after_advance(tracked)
  end

  # Hook for a provider that needs to do something else once state has
  # settled (LinkedIn appends an approximate-date note; nothing else does).
  def after_advance(_tracked); end

  def target_status
    status_event == "apply" ? "applied" : "favorited"
  end

  def apply_dates(tracked, applied_at)
    return unless applied_at
    return unless overwrite_applied_at? || tracked.applied_at.blank?

    tracked.update!(applied_at: applied_at)
  end

  def apply_outcome(tracked)
    outcome = outcome_for(@row)
    return unless outcome
    return if tracked.outcome.present? && !outcome_overwrite?

    tracked.update!(outcome: outcome, outcome_at: Time.current, outcome_source: outcome_source_for(@row))
  end
end
