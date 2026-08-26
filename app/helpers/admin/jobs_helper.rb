# frozen_string_literal: true

# One fixed accent per bus callsign so a participant reads as the same
# color everywhere on the Agent Wire tab -- daisyUI semantic color roles
# (defined in app/assets/tailwind/application.css), not literal palette
# hexes, so a future theme swap can't silently break this again.
module Admin::JobsHelper
  # Full literal class strings, not interpolated color names -- Tailwind's
  # scanner needs complete class tokens present verbatim in source to
  # generate them; a dynamically-built "border-l-#{color}" would never
  # appear as literal text anywhere and silently produce no styling.
  AGENT_WIRE_BORDER = {
    "agent-wwworkremote" => "border-l-accent",
    "agent-just3ws" => "border-l-secondary",
    "zdots" => "border-l-primary",
    "mike" => "border-l-warning"
  }.freeze
  AGENT_WIRE_DOT = {
    "agent-wwworkremote" => "bg-accent",
    "agent-just3ws" => "bg-secondary",
    "zdots" => "bg-primary",
    "mike" => "bg-warning"
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
