# frozen_string_literal: true

# Receives the raw JSON a tracker/status page already returns to its own
# tab -- the extension re-issues that page's own authenticated fetch and
# posts the response body here unmodified, rather than screen-scraping the
# DOM. Same shape as bin/import_indeed_applications' HAR replay; this is the
# live-capture twin of it, both routed through Applications::IndeedRowImporter
# so there is exactly one place that knows how to read the payload.
class Api::V0::OutcomesController < ApiController
  # POST /api/v0/outcomes/indeed
  # Body: the verbatim response of GET myjobs.indeed.com/api/v1/appStatusJobs
  #   { "body": { "appStatusJobs": [ {...}, ... ] } }
  def indeed
    return render_missing_rows if indeed_rows.empty?

    render json: import_summary
  end

  private

  def indeed_rows
    @indeed_rows ||= params.to_unsafe_h.dig("body", "appStatusJobs") || []
  end

  def render_missing_rows
    render json: { error: "No appStatusJobs in body" }, status: :unprocessable_content
  end

  def import_summary
    results = indeed_rows.map { |row| Applications::IndeedRowImporter.call(row, user: current_api_user) }
    { imported: results.size, outcomes: results.count { |r| r[:outcome] } }
  end

  def current_api_user
    @current_api_user ||= User.first
  end
end
