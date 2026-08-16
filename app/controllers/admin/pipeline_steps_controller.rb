# frozen_string_literal: true

class Admin::PipelineStepsController < Admin::ApplicationController
  # Explicit literal-symbol dispatch table, not dynamic send("#{params[:status]}!") --
  # Brakeman flags any send/public_send built from user input as unsafe reflection
  # even when pre-checked against an allowlist, since it can't verify the check
  # happens on every call path. A fixed hash keeps the AASM event names as literals.
  STATUS_EVENTS = {
    "favorite" => %i[favorite! may_favorite?],
    "apply" => %i[apply! may_apply?],
    "interview" => %i[interview! may_interview?],
    "offer" => %i[offer! may_offer?],
    "archive" => %i[archive! may_archive?],
    "ignore" => %i[ignore! may_ignore?]
  }.freeze

  def create
    @job_posting = JobPosting.find(params.expect(:job_posting_id))
    log_activity
    respond_after_logging
  end

  private

  # Explicit param, not respond_to/format negotiation -- Turbo Drive sends
  # `Accept: text/vnd.turbo-stream.html` on every form submission by
  # default, not just ones with a data-turbo-stream flag, so format.turbo_stream
  # would silently hijack every OTHER status button sharing this action
  # (Favorite, Apply, ...) across every view, not just the one caller that
  # actually wants a card removed. remove_card is only sent by
  # job_postings/index.html.erb's "ignore" button.
  def respond_after_logging
    if params[:remove_card] == "true"
      render turbo_stream: turbo_stream.remove(@job_posting)
    else
      redirect_to admin_job_posting_path(@job_posting), notice: "Activity logged."
    end
  end

  # Handle status transitions or manual notes
  def log_activity
    if params[:status].present?
      apply_status_event
    elsif params[:note].present?
      log_note_step
    end
  end

  # Checks the transition is actually legal from the current state -- a
  # double-click or stale page (e.g. two "Not interested" clicks before the
  # card is removed) would otherwise raise AASM::InvalidTransition instead
  # of just no-op'ing.
  def apply_status_event
    bang, guard = STATUS_EVENTS[params[:status]]
    return unless bang && @job_posting.public_send(guard)

    @job_posting.public_send(bang)
    log_status_change_step
  end

  def log_status_change_step
    @job_posting.pipeline_steps.create!(
      status: params[:status],
      note: "Status changed to #{params[:status]}",
      user: current_user
    )
  end

  # One cohesive create! call -- splitting it further would obscure it,
  # not simplify it.
  # rubocop:disable Metrics/MethodLength
  def log_note_step
    @job_posting.pipeline_steps.create!(
      status: "noted",
      note: params[:note],
      link: params[:link],
      artifacts: params[:artifacts],
      user: current_user
    )
  end
  # rubocop:enable Metrics/MethodLength
end
