# frozen_string_literal: true

# Human decisions on a single recorded GuidedSessionEvent -- the approval
# gate (TASK-112 AC#4) and the intent/classification annotation (AC#3).
# Split out of GuidedSessionsController so session lifecycle stays separate
# from per-transition review. Neither action touches the observable browser
# evidence; they record the human's reading of it.
class GuidedSessions::EventsController < ApplicationController
  before_action :set_event

  # AC#4: only a pending event can receive an approval decision, and the
  # decision is always explicit -- nothing here approves on the actor's behalf.
  def approval
    return reject("Only pending events can receive an approval decision.") unless approval_allowed?

    @event.update!(approval_state: decision)
    emit_signal(:guided_approval_decided, "reorientation", decision)
    redirect_back_to_event("Approval decision recorded: #{decision}.")
  end

  # AC#3: re-classify a transition (intent, requirement, reversibility,
  # approval_state). The model still enforces "irreversible => must be gated".
  def update
    return reject(@event.errors.full_messages.to_sentence) unless @event.update(annotation_params)

    emit_signal(:guided_transition_reclassified, @event.phase, "success")
    redirect_back_to_event("Transition reclassified.")
  end

  private

  def set_event
    @session = GuidedSession.find(params.expect(:id))
    @event = @session.guided_session_events.find(params.expect(:event_id))
  end

  def decision = params.expect(:approval_state)

  def approval_allowed?
    @event.approval_state == "pending" && GuidedSessionEvent::APPROVAL_STATES.include?(decision) &&
      decision != "not_required"
  end

  def annotation_params
    params.expect(guided_session_event: %i[intent requirement reversibility approval_state])
  end

  def redirect_back_to_event(notice)
    redirect_to guided_session_path(@session, anchor: "event-#{@event.id}"), notice: notice
  end

  def reject(alert)
    redirect_to guided_session_path(@session), alert: alert
  end

  def emit_signal(name, stage, outcome)
    Wwwr::ProcessSignals.emit(name, process: "guided_application_session", stage: stage,
                                    outcome: outcome, phase: @event.phase)
  end
end
