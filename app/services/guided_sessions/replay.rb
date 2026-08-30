# frozen_string_literal: true

# Drives a GuidedSessionReplay through the ReplayPlan one confirmed step at a
# time (TASK-133). Bounded Agency contract, enforced here and asserted by a
# guardrail spec:
#   - a `fill` step only ever populates fields from the recorded answers;
#   - it NEVER emits a click / navigate / submit instruction;
#   - a `gate` step stops the replay and, once approved, ends it.
class GuidedSessions::Replay
  SANDBOX_PROVIDERS = %w[sandbox wwworkremote.localhost].freeze

  class Error < StandardError
  end

  def self.start(guided_session, allow_real_site: false)
    new(guided_session).start(allow_real_site: allow_real_site)
  end

  def initialize(guided_session)
    @session = guided_session
  end

  def start(allow_real_site:)
    guard_startable!(allow_real_site)
    @session.guided_session_replays.create!(allow_real_site: allow_real_site)
  end

  def guard_startable!(allow_real_site)
    reason = start_blocker(allow_real_site)
    raise Error, reason if reason
  end

  def start_blocker(allow_real_site)
    return "replay needs a completed guided session" unless @session.status == "completed"
    return "a replay is already running" if @session.guided_session_replays.active.exists?
    "real-site replay is not enabled for this run" if real_site? && !allow_real_site
  end

  # The instruction for the replay's current cursor -- one of:
  #   { action: "fill", step: n, fields: [{field_key, field_label, source}] }
  #   { action: "advance", step: n }          (nothing to fill; move the cursor)
  #   { action: "gate", step: n, reason: }    (stop; approve to end)
  #   { action: "done" }
  def next_step(replay)
    step = plan[:steps][replay.current_step]
    return { action: "done" } unless step
    return gate_instruction(replay, step) if step.disposition == :pause

    fill_or_advance(replay)
  end

  def advance(replay)
    raise Error, "cannot advance from a gate" if next_step(replay)[:action] == "gate"

    replay.update!(current_step: replay.current_step + 1)
    replay.update!(status: "completed", ended_at: Time.current, ended_reason: "reached the end") if finished?(replay)
    replay
  end

  # Approving the gate records the decision and ENDS the replay -- it never
  # resumes provider action past a commitment boundary (scoping decision).
  def approve_gate(replay)
    replay.update!(status: "completed", ended_at: Time.current, ended_reason: "gate approved -- handed back to human")
  end

  def stop(replay)
    replay.update!(status: "stopped", ended_at: Time.current, ended_reason: "stopped by the actor")
  end

  private

  def plan
    @plan ||= GuidedSessions::ReplayPlan.call(@session)
  end

  def real_site?
    SANDBOX_PROVIDERS.none? { |p| @session.provider.to_s.include?(p) }
  end

  def finished?(replay)
    replay.current_step >= plan[:steps].size
  end

  def gate_instruction(replay, step)
    replay.update!(status: "paused_at_gate")
    { action: "gate", step: replay.current_step, reason: step.reason }
  end

  def fill_or_advance(replay)
    fields = recorded_fields
    return { action: "advance", step: replay.current_step } if fields.empty?

    { action: "fill", step: replay.current_step, fields: fields }
  end

  def recorded_fields
    ujp = @session.user_job_posting
    return [] unless ujp

    ujp.application_field_answers.order(:provided_at).map do |answer|
      { field_key: answer.field_key, field_label: answer.field_label, source: answer.answer_source }
    end
  end
end
