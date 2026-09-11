# frozen_string_literal: true

# Legibility surfaces for the harness (guided-session + datalake subsystem) --
# ADR 010 / TASK-125. Read-only: nothing here changes pipeline state.
module HarnessHelper
  # [css, label] for the furthest harness state a tracked application reached,
  # matching pipeline_status_badge / answer_source_badge's shape. nil when the
  # posting has never been through the harness (render nothing).
  HARNESS_BADGE = {
    in_progress: ["border-warning/40 text-warning", "Harness: in progress"],
    recorded: ["border-primary/40 text-primary", "Harness: recorded"],
    compared: ["border-accent/40 text-accent", "Harness: compared"]
  }.freeze

  def harness_badge(user_job)
    return nil if user_job.blank?

    HARNESS_BADGE[user_job.harness_state]
  end
end
