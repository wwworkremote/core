# frozen_string_literal: true

class AddPlaybackPositionToGuidedSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :guided_sessions, :playback_position, :integer, null: false, default: 0
  end
end
