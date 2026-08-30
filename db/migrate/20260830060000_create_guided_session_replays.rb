# frozen_string_literal: true

# TASK-133: a supervised replay of a completed GuidedSession. It re-fills known
# fields from the recorded answers, one confirmed step at a time, and stops at
# every ReplayPlan gate. It never clicks Next / Continue / Submit -- every
# navigation or transmission is a human action (Bounded Agency).
class CreateGuidedSessionReplays < ActiveRecord::Migration[8.1]
  def change
    create_replays_table
    add_index :guided_session_replays, %i[guided_session_id status]
  end

  def create_replays_table
    # rubocop:disable-next Metrics/MethodLength
    create_table :guided_session_replays do |t|
      t.references :guided_session, null: false, foreign_key: true
      t.string :status, null: false, default: "running"
      t.integer :current_step, null: false, default: 0
      t.boolean :allow_real_site, null: false, default: false
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.string :ended_reason
      t.timestamps
    end
  end
end
