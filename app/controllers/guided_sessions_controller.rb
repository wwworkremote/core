# frozen_string_literal: true

class GuidedSessionsController < ApplicationController
  # Playback position is local presentation state; it cannot submit, alter,
  # or transmit a provider/application action.
  skip_before_action :verify_authenticity_token, only: :playback
  before_action :set_guided_session, only: %i[show playback approval]

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

  private

  def set_guided_session
    @guided_session = GuidedSession.find(params.expect(:id))
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
