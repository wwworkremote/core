# frozen_string_literal: true

# Upserts one row of Indeed's api/v1/appStatusJobs shape -- the exact JSON
# that endpoint returns, whether it arrived via a HAR capture
# (bin/import_indeed_applications) or a live authenticated fetch from the
# extension while Mike is on myjobs.indeed.com (Api::V0::OutcomesController).
# One import path, two callers, so a schema change only needs fixing once.
class Applications::IndeedRowImporter
  # Employer signal beats self-report; REJECTED beats REVIEWED so a later
  # "still pending" self-report can't downgrade a rejection Indeed already
  # confirmed elsewhere in the same payload.
  OUTCOME_RANK = { "REJECTED" => 3, "REVIEWED" => 2, "CLOSED" => 1 }.freeze

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
    { posting: posting, applied_at: applied_at, outcome: outcome_for(@row).first }
  end

  private

  def signature
    Digest::SHA256.hexdigest("indeed-app-#{@row['jobKey']}")
  end

  def upsert_posting
    posting = find_posting
    posting ? backfill(posting) : create_posting
  end

  def create_posting
    JobPosting.create!(new_posting_attrs)
  end

  def new_posting_attrs
    { signature: signature, title: @row["jobTitle"].to_s.strip,
      company_name: @row.dig("company", "name").to_s.strip, location: @row["location"],
      source_id: indeed_source_id, target_url: @row["jobUrl"], status: "none", crawl_status: "pending" }
  end

  def find_posting
    Applications::PostingMatcher.call(
      signature: signature, native_id_fragment: "jk=#{@row['jobKey']}", target_url: @row["jobUrl"],
      company: @row.dig("company", "name"), title: @row["jobTitle"]
    )
  end

  def backfill(posting)
    company = @row.dig("company", "name").to_s.strip
    posting.update!(company_name: company) if posting.company_name.blank? && company.present?
    posting
  end

  # JobPosting#source resolves to plain ::Source (an ingestion-event row
  # belonging to an Origin), NOT JobBoards::Source -- a same-named, unrelated
  # model backed by its own table. Using the latter's id satisfies the FK by
  # coincidence in a shared dev DB (both tables happen to have overlapping id
  # ranges) but is semantically wrong and breaks the moment the tables don't
  # coincidentally overlap, as the request spec's isolated test DB proved.
  # Mirrors Leads::CaptureService#resolve_source, the pattern the extension's
  # own real capture path already uses.
  def indeed_source_id
    @indeed_source_id ||= begin
      origin = Origin.find_or_create_by!(name: "Indeed")
      Source.find_or_create_by!(signature: "indeed-outcome-import") { |s| s.origin = origin; s.name = "Indeed" }.id
    end
  end

  def applied_at_from(row)
    row["applyTime"] && Time.zone.at(row["applyTime"].to_i / 1000)
  end

  def outcome_candidates(row)
    { row.dig("statuses", "candidateStatus", "status") => "employer",
      row.dig("statuses", "selfReportedStatus", "status") => "self_reported",
      row.dig("statuses", "employerJobStatus", "status") => "employer" }.compact
  end

  def outcome_for(row)
    candidates = outcome_candidates(row)
    best = candidates.keys.max_by { |s| OUTCOME_RANK[s] || 0 }
    return [nil, nil] unless best && OUTCOME_RANK.key?(best)

    [best.downcase, candidates[best]]
  end

  # UserJobPosting owns pipeline state entirely as of TASK-82 phase 3 --
  # JobPosting no longer has favorite!/apply! at all.
  def advance(posting, applied_at)
    tracked = tracked_record(posting)
    tracked.record_status_event!("apply") if tracked.status != "applied"
    apply_dates(tracked, applied_at)
    apply_outcome(tracked)
  end

  def apply_dates(tracked, applied_at)
    tracked.update!(applied_at: applied_at) if applied_at && tracked.applied_at.blank?
  end

  def tracked_record(posting)
    @user.user_job_postings.find_or_create_by!(job_posting: posting)
  end

  def apply_outcome(tracked)
    outcome, source = outcome_for(@row)
    tracked.update!(outcome: outcome, outcome_at: Time.current, outcome_source: source) if outcome
  end
end
