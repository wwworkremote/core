# frozen_string_literal: true

class DiceController < ApplicationController
  def roll
    current_span = OpenTelemetry::Trace.current_span

    rolled = rand(1..6).to_s

    current_span.add_attributes({ 'com.dice.roll.rolled' => rolled })

    render(json: rolled)
  end
end
