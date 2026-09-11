# frozen_string_literal: true

# Receives the raw JSON a tracker/status page already returns to its own
# tab -- the extension re-issues that page's own authenticated fetch(es) and
# posts the response body/bodies here unmodified, rather than screen-scraping
# the DOM. Same shape as the bin/import_* HAR-replay scripts; these are the
# live-capture twins, both routed through the matching Applications::*RowImporter
# so there is exactly one place per source that knows how to read its payload.
class Api::V0::OutcomesController < ApiController
  # POST /api/v0/outcomes/indeed
  # Body: the verbatim response of GET myjobs.indeed.com/api/v1/appStatusJobs
  #   { "body": { "appStatusJobs": [ {...}, ... ] } }
  def indeed
    return render_missing_rows("appStatusJobs") if indeed_rows.empty?

    results = indeed_rows.map { |row| Applications::IndeedRowImporter.call(row, user: current_api_user) }
    render json: import_summary(results)
  end

  # POST /api/v0/outcomes/greenhouse
  # Body: the extension fetches every page itself (the endpoint is paginated)
  # and posts the raw responses as an array, unflattened, deduped here --
  #   { "pages": [ <raw applications.json body>, ... ] }
  # so the extension stays a dumb pipe with no Greenhouse-shape knowledge of
  # its own, same as the Indeed capture script.
  def greenhouse
    return render_missing_rows("applications") if greenhouse_apps.empty?

    results = greenhouse_apps.map { |app| Applications::GreenhouseRowImporter.call(app, user: current_api_user) }
    render json: import_summary(results)
  end

  private

  def indeed_rows
    @indeed_rows ||= params.to_unsafe_h.dig("body", "appStatusJobs") || []
  end

  # Reads both active.applications and inactive.applications, defensively --
  # the HAR-replay backfill only ever captured active_only=true (verified
  # shape: {"active"=>{"applications"=>[...]}}), so whether an unqualified
  # request also returns an "inactive" bucket is unverified. dig returns nil
  # safely either way; if it IS there, this is the only path in the app that
  # can see a Greenhouse rejection (currentStage comes back null otherwise --
  # see Applications::GreenhouseRowImporter).
  def greenhouse_apps
    @greenhouse_apps ||= greenhouse_pages.flat_map { |page| apps_in(page) }.uniq { |a| a["id"] }
  end

  def greenhouse_pages
    params.to_unsafe_h.fetch("pages", [])
  end

  def apps_in(page)
    (page.dig("active", "applications") || []) + (page.dig("inactive", "applications") || [])
  end

  def render_missing_rows(key)
    render json: { error: "No #{key} in body" }, status: :unprocessable_content
  end

  def import_summary(results)
    { imported: results.size, outcomes: results.count { |r| r[:outcome] } }
  end

  def current_api_user
    @current_api_user ||= User.first
  end
end
