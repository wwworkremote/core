# frozen_string_literal: true

class AddIngestionPausedAndExcludedFromResultsToJobBoardsSources < ActiveRecord::Migration[8.1]
  def change
    # rubocop:disable Rails/BulkChangeTable -- strong_migrations can't safety-check inside change_table
    add_column :job_boards_sources, :ingestion_paused, :boolean, default: false, null: false
    add_column :job_boards_sources, :excluded_from_results, :boolean, default: false, null: false
    # rubocop:enable Rails/BulkChangeTable
  end
end
