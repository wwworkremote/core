# frozen_string_literal: true

class AddTrackingToJobBoardsSources < ActiveRecord::Migration[8.0]
  def change
    add_column :job_boards_sources, :last_synced_at, :datetime
    add_column :job_boards_sources, :last_ingested_at, :datetime
  end
end
