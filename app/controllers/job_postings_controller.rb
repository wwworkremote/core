# frozen_string_literal: true

class JobPostingsController < ApplicationController
  include JobPostingFiltering

  # Flat inline-edit-form fields (TASK-148). The jsonb-backed and array-backed
  # ones (remote, salary, employment_type, countries_text, tags_text) are
  # virtual accessors on JobPosting that translate to `data` / `tags`.
  EDIT_FIELDS = %i[title company_name location target_url published_at employment_type
                   remote salary_min salary_max currency countries_text tags_text].freeze

  # Lets "Not Interested"/"Expired" redirect back to wherever triage started.
  before_action(only: %i[show update]) { @return_to = safe_return_path(request.referer) }

  def index
    assign_filter_params
    @job_postings = filtered_job_postings.page(params[:page]).per(20)
  end

  def show
    @job_posting = JobPosting.includes(:contacts, source: :origin).find(params.expect(:id))
    ahoy.track "Viewed Job Posting", job_posting_id: @job_posting.id, title: @job_posting.title
  end

  # Corrects scraped-data damage inline from the show page (TASK-86, widened by
  # TASK-148). Everything here is user-corrected scrape output. Deliberately
  # excludes :status: writing that column directly would skip the AASM guards,
  # same reason UserJobPosting's update already refuses it. A typo fix and a
  # pipeline transition are different actions and must stay different code paths.
  def update
    @job_posting = JobPosting.find(params.expect(:id))
    return render_edit_errors unless @job_posting.update(job_posting_params)

    redirect_to job_posting_path(@job_posting), notice: "Posting updated."
  end

  def reformat
    job_posting = mark_reformatting!(JobPosting.find(params.expect(:id)))
    JobPostingReformatJob.perform_later(job_posting.id)
    render turbo_stream: description_replace_stream(job_posting)
  end

  # TASK-86: clicking through to the employer's site is intent, so it
  # favorites -- but never marks applied. Auto-applying on an outbound click
  # is exactly the funnel inflation bin/import_linkedin_tracker deliberately
  # avoids by recording LinkedIn's clicked_apply as favorited, not applied.
  # "Mark Applied" already exists in the Activity panel's available_status_events
  # once a posting is favorited, so that's the "did you finish?" affordance --
  # no new UI needed for it. Tracking and the open-redirect guard stay
  # OutboundLinksController's job unchanged; this only favorites, then hands
  # off to it, so the click is recorded exactly as it is today.
  def apply_on_site
    job_posting = JobPosting.find(params.expect(:id))
    favorite_for_current_user(job_posting)
    redirect_to outbound_link_path(url: job_posting.target_url, job_posting_id: job_posting.id)
  end

  private

  # UserJobPosting owns pipeline state entirely as of TASK-82 phase 3 --
  # JobPosting no longer has favorite! at all.
  def favorite_for_current_user(job_posting)
    current_user.user_job_postings.find_or_create_by!(job_posting: job_posting).record_status_event!("favorite")
  end

  def render_edit_errors
    @editing = params[:section].presence || "core"
    render :show, status: :unprocessable_content
  end

  def job_posting_params
    params.expect(job_posting: EDIT_FIELDS)
  end

  def mark_reformatting!(job_posting)
    job_posting.update!(data: job_posting.data.merge("reformatting" => true))
    job_posting
  end

  def description_replace_stream(job_posting)
    turbo_stream.replace(
      ActionView::RecordIdentifier.dom_id(job_posting, :description),
      partial: "job_postings/description", locals: { job_posting: job_posting }
    )
  end
end
