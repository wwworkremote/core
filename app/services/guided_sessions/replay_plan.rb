# frozen_string_literal: true

# TASK-112 AC#5 (planning half): given a recorded session, classify each
# transition as one a later replay could advance deterministically, or one it
# must pause on for Mike -- unknown, ambiguous, irreversible, or approval-gated.
#
# This is read-only. It produces the plan a replay *would* follow; it does not
# drive a browser or fill anything. Execution is a separate, explicitly-scoped
# effort (TASK-134) -- Bounded Agency: nothing here or downstream fills or
# submits without Mike's explicit action.
class GuidedSessions::ReplayPlan
  Step = Data.define(:event, :disposition, :reason)
  REPLAY_REASON = "deterministic, reversible, no approval needed"

  # A transition is only auto-advanceable if every safety signal says so.
  def self.call(guided_session) = new(guided_session).call

  def initialize(guided_session)
    @guided_session = guided_session
  end

  def call
    steps = ordered_events.map { |event| classify(event) }
    { steps: steps, replayable: steps.count { |s| s.disposition == :replay },
      gates: steps.count { |s| s.disposition == :pause } }
  end

  private

  def ordered_events
    @guided_session.guided_session_events.order(:occurred_at, :id)
  end

  def classify(event)
    reason = pause_reason(event)
    return Step.new(event: event, disposition: :pause, reason: reason) if reason

    Step.new(event: event, disposition: :replay, reason: REPLAY_REASON)
  end

  def pause_reason(event)
    return "irreversible move" if event.reversibility == "irreversible"
    return "approval gate (#{event.approval_state})" if %w[pending denied].include?(event.approval_state)
    return "reached a commitment boundary" if event.kind == "submission_attempted"

    nil
  end
end
