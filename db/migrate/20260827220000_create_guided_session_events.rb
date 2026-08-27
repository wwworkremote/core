# frozen_string_literal: true

class CreateGuidedSessionEvents < ActiveRecord::Migration[8.0]
  EVENT_COLUMNS = [
    [:references, :guided_session, { null: false, foreign_key: true }],
    [:string, :phase, { null: false }],
    [:string, :kind, { null: false }],
    [:string, :action, { null: false }],
    [:text, :intent, { null: false }],
    [:string, :requirement, { null: false }],
    [:string, :reversibility, { null: false }],
    [:string, :approval_state, { null: false }],
    %i[string page_url],
    [:jsonb, :evidence, { null: false, default: {} }],
    [:datetime, :occurred_at, { null: false }],
    [:timestamps]
  ].freeze

  def change
    define_table
    add_index :guided_session_events, %i[guided_session_id occurred_at]
  end

  private

  def define_table
    create_table :guided_session_events do |t|
      EVENT_COLUMNS.each { |column| t.public_send(*column) }
      t.timestamps
    end
  end
end
