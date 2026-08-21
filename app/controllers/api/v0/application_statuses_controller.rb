# frozen_string_literal: true

# Lets the Chrome extension record a lifecycle transition at the moment it
# actually happens -- the user is sitting on the ATS application page, not in
# the app, so requiring a trip back to the web UI is how "applied" never got
# recorded. Same path as the web UI: UserJobPosting#record_status_event!.
class Api::V0::ApplicationStatusesController < ApiController
  def show
    render json: status_payload(existing_or_new)
  end

  def create
    record = tracked_record
    logged = record.record_status_event!(params[:event])

    render json: status_payload(record).merge(success: logged.present?)
  end

  private

  def tracked_record
    current_api_user.user_job_postings.find_or_create_by!(job_posting: job_posting)
  end

  def status_payload(record)
    { job_posting_id: job_posting.id, status: record.status, available_events: record.available_status_events }
  end

  # An unsaved record reports the same `none` status and event set the user
  # would get on first save, so `show` needs no separate not-yet-tracked branch.
  def existing_or_new
    current_api_user.user_job_postings.find_by(job_posting: job_posting) || UserJobPosting.new
  end

  def current_api_user
    @current_api_user ||= User.first
  end

  def job_posting
    @job_posting ||= JobPosting.find(params.expect(:job_posting_id))
  end
end
