# frozen_string_literal: true

class Admin::PipelineStepsController < Admin::ApplicationController
  # ignore/expire are facts about the posting itself -- JobPosting owns
  # them directly. Explicit literal-symbol dispatch table, not dynamic
  # send("#{params[:status]}!") -- Brakeman flags any send/public_send
  # built from user input as unsafe reflection even when pre-checked
  # against an allowlist, since it can't verify the check happens on every
  # call path. A fixed hash keeps the AASM event names as literals.
  LIFECYCLE_EVENTS = {
    "ignore" => %i[ignore! may_ignore?],
    "expire" => %i[expire! may_expire?]
  }.freeze

  # favorite/apply/interview/archive are Mike's own pipeline stage --
  # UserJobPosting owns them (TASK-82). JobPosting has no such methods as
  # of phase 3.
  PIPELINE_EVENTS = %w[favorite apply interview archive].freeze

  # Whitelisted by key, not passed through raw -- these are jsonb-column
  # values, not model attributes, so strong params' usual guard against
  # mass-assigning unrelated columns doesn't apply, but an attacker-supplied
  # key set could still bloat the column with arbitrary junk.
  REASON_TAG_KEYS = %w[industry skills_seniority compensation location_remote].freeze

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
    return render turbo_stream: turbo_stream.remove(@job_posting) if params[:remove_card] == "true"

    redirect_to redirect_target, notice: "Activity logged."
  end

  # Not interested/Expired redirect back to wherever triage started (see
  # JobPostingsController#show) instead of this now-dismissed posting's own
  # page. safe_local_path re-validates the submitted value even though it
  # originated from our own hidden field -- defense in depth against a
  # tampered form value (e.g. a protocol-relative "//evil.com" open redirect).
  def redirect_target
    return job_posting_triage_path if params[:from_triage] == "true"

    dismissal_return_to || job_posting_path(@job_posting)
  end

  def dismissal_return_to
    return unless %w[ignore expire].include?(params[:status])

    safe_local_path(params[:return_to])
  end

  # Handle status transitions or manual notes
  def log_activity
    if params[:status].present?
      apply_status_event
    elsif params[:note].present?
      log_note_step
    end
  end

  # Dispatches on which model actually owns params[:status] -- see
  # LIFECYCLE_EVENTS/PIPELINE_EVENTS above. "offer" is neither: it's the
  # employer's decision (TASK-82/TASK-94), recorded as an outcome, not a
  # status transition on either model.
  # rubocop:disable-next Metrics/MethodLength, Metrics/AbcSize
  def apply_status_event
    if LIFECYCLE_EVENTS.key?(params[:status])
      apply_lifecycle_event
    elsif params[:status] == "offer"
      apply_offer_outcome
    elsif PIPELINE_EVENTS.include?(params[:status])
      apply_pipeline_event
    end
  end

  # A double-click or stale page (e.g. two "Not interested" clicks before
  # the card is removed) would otherwise raise AASM::InvalidTransition
  # instead of just no-op'ing.
  def apply_lifecycle_event
    bang, guard = LIFECYCLE_EVENTS[params[:status]]
    return unless @job_posting.public_send(guard)

    @job_posting.public_send(bang)
    log_status_change_step
    record_triage_history
  end

  # log_status_change_step still writes through @job_posting.pipeline_steps
  # -- PipelineStep belongs_to both job_posting and user regardless of
  # which model's own state actually changed. advance_pipeline_state! (not
  # record_status_event!) because log_status_change_step already creates
  # this click's PipelineStep, with triage reason_tags UserJobPosting
  # knows nothing about -- record_status_event! would create a second,
  # plainer one for the same click. Its own may_#{event}? guard makes an
  # illegal/no-op transition here a silent no-op too, matching
  # apply_lifecycle_event's behavior.
  def apply_pipeline_event
    return unless user_job_posting.advance_pipeline_state!(params[:status])

    log_status_change_step
    record_triage_history
  end

  # Same outcome column "Mark Rejected" already writes to (see
  # UserJobPostingsController::MANUAL_OUTCOMES) -- offered/rejected are the
  # same kind of fact, not a stage.
  def apply_offer_outcome
    user_job_posting.update!(outcome: "offered", outcome_at: Time.current, outcome_source: "manual")
    log_status_change_step
    record_triage_history
  end

  def user_job_posting
    @user_job_posting ||= current_user.user_job_postings.find_or_create_by!(job_posting: @job_posting)
  end

  # Lets the triage queue offer a "Back" link to the previous decision so a
  # misclick can be corrected on that posting's own show page (which already
  # has the full set of status-transition buttons, including restore).
  # Capped at 20 so the session cookie doesn't grow unbounded across a long
  # triage streak.
  # rubocop:disable-next Metrics/AbcSize
  def record_triage_history
    return unless params[:from_triage] == "true"

    history = session[:triage_history].presence || []
    session[:triage_history] = (history << @job_posting.id).last(20)
  end

  # One cohesive create! call plus its tracking event -- splitting it
  # further would obscure it, not simplify it.
  # rubocop:disable-next Metrics/MethodLength, Metrics/AbcSize
  def log_status_change_step
    ahoy.track "Pipeline Status Changed", status: params[:status], job_posting_id: @job_posting.id
    @job_posting.pipeline_steps.create!(
      status: params[:status],
      note: params[:note].presence || "Status changed to #{params[:status]}",
      reason_tags: triage_reason_tags,
      user: current_user
    )
  end

  # params.expect(:reason_tags) (the rubocop-suggested rewrite) is wrong
  # here: expect on a bare key treats it as a required *scalar*, so it
  # raises ActionController::ParameterMissing given the Hash reason_tags
  # actually is. Permit + to_h is the correct shape for an optional,
  # arbitrarily-keyed nested hash.
  # rubocop:disable-next Rails/StrongParametersExpect
  def triage_reason_tags
    return {} if params[:reason_tags].blank?

    params[:reason_tags].permit(*REASON_TAG_KEYS).to_h.compact_blank
  end

  # One cohesive create! call -- splitting it further would obscure it,
  # not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def log_note_step
    @job_posting.pipeline_steps.create!(
      status: "noted",
      note: params[:note],
      link: params[:link],
      artifacts: params[:artifacts],
      user: current_user
    )
  end
end
