# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

class CreateGuidedSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :guided_sessions do |t|
      t.string :session_token, null: false
      t.string :source_url, null: false
      t.string :provider, null: false
      t.string :phase, null: false, default: "intake"
      t.string :status, null: false, default: "active"
      t.datetime :started_at, null: false
      t.timestamps
    end

    add_index :guided_sessions, :session_token, unique: true
  end
end
# rubocop:enable Metrics/MethodLength
