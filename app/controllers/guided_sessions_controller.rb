# frozen_string_literal: true

class GuidedSessionsController < ApplicationController
  # Playback position is local presentation state; it cannot submit, alter,
  # or transmit a provider/application action.
  REVIEWER = ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com")
  NO_URL_ALERT = "This posting has no application URL to record."
  SESSION_STARTED_NOTICE = "Supervised application session started."

  skip_before_action :verify_authenticity_token, only: :playback
  before_action :set_guided_session, only: %i[show playback approval complete compare create_disposition]

  def index
    @guided_sessions = GuidedSession.includes(user_job_posting: { job_posting: :company })
                                    .order(started_at: :desc).limit(100)
  end

  def show
    @events = @guided_session.guided_session_events.order(:occurred_at, :id)
  end

  def new
    @guided_session = GuidedSession.new(purpose: "application_research")
  end

  def create
    @guided_session = GuidedSession.new(guided_session_params)

    return redirect_to guided_session_path(@guided_session), notice: "Guided session started." if @guided_session.save

    render :new, status: :unprocessable_content
  end

  # Entry seam (ADR 010 §1): start a supervised application from a job posting.
  # Creates the tracked UserJobPosting if none exists, links the session to it.
  # Advisory -- never advances the UserJobPosting's own AASM state.
  def create_from_posting
    return redirect_to(job_posting_path(posting), alert: NO_URL_ALERT) if posting.target_url.blank?

    redirect_to guided_session_path(start_supervised_session), notice: SESSION_STARTED_NOTICE
  end

  def playback
    position = Integer(params.expect(:position), exception: false)
    return render_invalid_position if invalid_position?(position)

    @guided_session.update!(playback_position: position)
    render json: { success: true, position: @guided_session.playback_position }
  end

  def approval
    event = @guided_session.guided_session_events.find(params.expect(:event_id))
    return approval_rejected unless approval_allowed?(event)

    approval_state = params.expect(:approval_state)
    record_approval(event, approval_state)
  end

  def complete
    @guided_session.complete!
    redirect_to guided_session_path(@guided_session), notice: "Session completed; a reference comparison ran."
  end

  def compare
    Scenarios::RecordComparison.call(@guided_session, trigger: "manual")
    redirect_to guided_session_path(@guided_session), notice: "Compared against the provider reference."
  end

  def create_disposition
    finding = session_finding(params.expect(:finding_id))
    finding.finding_dispositions.create!(disposition_attrs(finding))
    redirect_to guided_session_path(@guided_session), notice: "Disposition recorded."
  end

  private

  def session_finding(finding_id)
    ComparisonFinding.where(reference_comparison_id: @guided_session.reference_comparisons.select(:id)).find(finding_id)
  end

  def disposition_attrs(finding)
    value = params.expect(:value)
    { value: value, rationale: params[:rationale].presence, reviewer: REVIEWER, reviewer_label: "Mike",
      source_disposition_id: (finding.suggested_disposition_id if finding.suggested_disposition&.value == value) }
  end

  def set_guided_session
    @guided_session = GuidedSession.find(params.expect(:id))
  end

  def posting
    @posting ||= JobPosting.find(params.expect(:id))
  end

  def start_supervised_session
    user_job = current_user.user_job_postings.find_or_create_by!(job_posting: posting)
    GuidedSession.create!(source_url: posting.target_url, purpose: "application_execution", user_job_posting: user_job)
  end

  def guided_session_params
    params.expect(guided_session: %i[source_url purpose])
  end

  def invalid_position?(position)
    position.nil? || position.negative?
  end

  def approval_allowed?(event)
    approval_state = params.expect(:approval_state)
    event.approval_state == "pending" &&
      GuidedSessionEvent::APPROVAL_STATES.include?(approval_state) &&
      approval_state != "not_required"
  end

  def approval_rejected
    redirect_to guided_session_path(@guided_session), alert: "Only pending events can receive an approval decision."
  end

  def record_approval(event, approval_state)
    event.update!(approval_state: approval_state)
    emit_guided_approval(event, approval_state)
    redirect_to guided_session_path(@guided_session), notice: "Approval decision recorded: #{approval_state}."
  end

  def render_invalid_position
    render json: { errors: ["Position must be a non-negative integer"] }, status: :unprocessable_content
  end

  def emit_guided_approval(event, approval_state)
    Wwwr::ProcessSignals.emit(:guided_approval_decided, process: "guided_application_session",
                                                        stage: "reorientation", outcome: approval_state,
                                                        phase: event.phase)
  end
end
