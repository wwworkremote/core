# frozen_string_literal: true

class AddScenarioToGuidedSessions < ActiveRecord::Migration[8.1]
  # guided_sessions was created 2026-08-27 and holds a handful of dev rows;
  # a plain add_reference is safe here.
  def change
    safety_assured do
      add_reference :guided_sessions, :scenario, null: true, foreign_key: true
    end
  end
end
