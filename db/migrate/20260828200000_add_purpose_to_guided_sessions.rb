# frozen_string_literal: true

class AddPurposeToGuidedSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :guided_sessions, :purpose, :string, null: false, default: "application_execution"
  end
end
