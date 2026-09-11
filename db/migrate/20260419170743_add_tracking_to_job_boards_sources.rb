# frozen_string_literal: true

class AddTrackingToJobBoardsSources < ActiveRecord::Migration[8.0]
  def change
    change_table :job_boards_sources, bulk: true do |t|
      t.datetime :last_synced_at
      t.datetime :last_ingested_at
    end
  end
end
