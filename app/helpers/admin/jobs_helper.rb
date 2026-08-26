# frozen_string_literal: true

# One fixed accent per bus callsign so a participant reads as the same
# color everywhere on the Agent Wire tab -- Dracula palette tokens already
# defined in app/assets/tailwind/application.css, not new colors.
module Admin::JobsHelper
  # Full literal class strings, not interpolated color names -- Tailwind's
  # scanner needs complete class tokens present verbatim in source to
  # generate them; a dynamically-built "border-l-dracula-#{color}" would
  # never appear as literal text anywhere and silently produce no styling.
  AGENT_WIRE_BORDER = {
    "agent-wwworkremote" => "border-l-dracula-cyan",
    "agent-just3ws" => "border-l-dracula-pink",
    "zdots" => "border-l-dracula-purple",
    "mike" => "border-l-dracula-yellow"
  }.freeze
  AGENT_WIRE_DOT = {
    "agent-wwworkremote" => "bg-dracula-cyan",
    "agent-just3ws" => "bg-dracula-pink",
    "zdots" => "bg-dracula-purple",
    "mike" => "bg-dracula-yellow"
  }.freeze
  DEFAULT_BORDER = "border-l-slate-600"
  DEFAULT_DOT = "bg-slate-600"

  def agent_wire_accent_class(participant)
    AGENT_WIRE_BORDER.fetch(participant, DEFAULT_BORDER)
  end

  def agent_wire_dot_class(participant)
    AGENT_WIRE_DOT.fetch(participant, DEFAULT_DOT)
  end
end
