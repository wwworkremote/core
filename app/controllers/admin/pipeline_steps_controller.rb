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
    "ignore" => %i[ignore! may_ignore?],
    "expire" => %i[expire! may_expire?]
  }.freeze

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

  # One cohesive create! call plus its tracking event -- splitting it
  # further would obscure it, not simplify it.
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def log_status_change_step
    ahoy.track "Pipeline Status Changed", status: params[:status], job_posting_id: @job_posting.id
    @job_posting.pipeline_steps.create!(
      status: params[:status],
      note: params[:note].presence || "Status changed to #{params[:status]}",
      reason_tags: triage_reason_tags,
      user: current_user
    )
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # params.expect(:reason_tags) (the rubocop-suggested rewrite) is wrong
  # here: expect on a bare key treats it as a required *scalar*, so it
  # raises ActionController::ParameterMissing given the Hash reason_tags
  # actually is. Permit + to_h is the correct shape for an optional,
  # arbitrarily-keyed nested hash.
  # rubocop:disable Rails/StrongParametersExpect
  def triage_reason_tags
    return {} if params[:reason_tags].blank?

    params[:reason_tags].permit(*REASON_TAG_KEYS).to_h.compact_blank
  end
  # rubocop:enable Rails/StrongParametersExpect

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
