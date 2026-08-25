# frozen_string_literal: true

# Upserts one row of my.greenhouse.io's applications.json shape -- shared by
# bin/import_greenhouse_applications' HAR replay and
# Api::V0::OutcomesController#greenhouse's live extension capture, same
# split as Applications::IndeedRowImporter.
#
# Outcome signal here is thinner than Indeed's: currentStage came back null
# across every application checked 2026-08-24 (employers not sharing stage
# with the candidate portal), so the only real signal is an application
# showing up in the "inactive" bucket at all -- Greenhouse flips an
# application inactive on rejection, withdrawal, or the req closing, and the
# portal doesn't say which. Recorded as "closed", not "rejected": that
# distinction is real and this app can't see it, so don't claim more
# certainty than the source has.
class Applications::GreenhouseRowImporter
  def self.call(app, user:)
    new(app, user).call
  end

  def initialize(app, user)
    @app = app
    @user = user
  end

  def call
    posting = upsert_posting
    applied_at = applied_at_from(@app)
    advance(posting, applied_at)
    { posting: posting, applied_at: applied_at, outcome: outcome_for(@app) }
  end

  private

  def signature
    Digest::SHA256.hexdigest("greenhouse-app-#{@app['id']}")
  end

  def upsert_posting
    posting = find_posting
    posting ? backfill(posting) : create_posting
  end

  def find_posting
    Applications::PostingMatcher.call(
      signature: signature, native_id_fragment: "/jobs/#{@app['job_post_id']}", target_url: @app["job_post_url"],
      company: @app["company_name"], title: @app["job_title"]
    )
  end

  def create_posting
    JobPosting.create!(new_posting_attrs)
  end

  def new_posting_attrs
    { signature: signature, title: @app["job_title"].to_s.strip, company_name: @app["company_name"].to_s.strip,
      location: @app["locations"], source_id: greenhouse_source_id, target_url: @app["job_post_url"],
      status: "none", crawl_status: "pending" }
  end

  def backfill(posting)
    company = @app["company_name"].to_s.strip
    posting.update!(company_name: company) if posting.company_name.blank? && company.present?
    posting
  end

  # Mirrors Leads::CaptureService#resolve_source -- see IndeedRowImporter for
  # why JobBoards::Source is the wrong model here.
  def greenhouse_source_id
    @greenhouse_source_id ||= begin
      origin = Origin.find_or_create_by!(name: "Greenhouse")
      Source.find_or_create_by!(signature: "greenhouse-app-import") { |s| s.origin = origin; s.name = "Greenhouse" }.id
    end
  end

  def applied_at_from(app)
    return nil if app["applied_at"].blank?

    Time.zone.parse(app["applied_at"])
  rescue ArgumentError, TypeError
    nil
  end

  def outcome_for(app)
    stage = app["currentStage"].to_s
    return "rejected" if stage.match?(/reject/i)
    return "closed" if app["inactive"] == true

    nil
  end

  # Same two-machine write as every other importer -- JobPosting and
  # UserJobPosting drift when only one is moved (TASK-82).
  def advance(posting, applied_at)
    advance_posting_status(posting)
    tracked = tracked_record(posting)
    tracked.record_status_event!("apply") if tracked.status != "applied"
    apply_dates(tracked, applied_at)
    apply_outcome(tracked)
  end

  def advance_posting_status(posting)
    posting.favorite! if posting.may_favorite?
    posting.apply! if posting.may_apply?
  end

  def tracked_record(posting)
    @user.user_job_postings.find_or_create_by!(job_posting: posting)
  end

  # Applied_at is always set here, unlike Indeed's blank-only fill: this is
  # the authoritative date for these rows, and a LinkedIn relative-age
  # approximation may have written a worse one first.
  def apply_dates(tracked, applied_at)
    tracked.update!(applied_at: applied_at) if applied_at
  end

  def apply_outcome(tracked)
    outcome = outcome_for(@app)
    tracked.update!(outcome: outcome, outcome_at: Time.current, outcome_source: "employer") if outcome
  end
end
