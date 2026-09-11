# frozen_string_literal: true

class CreatePgheroQueryStats < ActiveRecord::Migration[7.0]
  def change
    create_pghero_query_stats_table
    add_index :pghero_query_stats, %i[database captured_at]
  end

  private

  # Schema mirrors the pghero gem's own generator output verbatim --
  # deliberately no created_at/updated_at, since pghero itself queries
  # only the columns below.
  # rubocop:disable Metrics/MethodLength, Rails/CreateTableWithTimestamps
  def create_pghero_query_stats_table
    create_table :pghero_query_stats do |t|
      t.text :database
      t.text :user
      t.text :query
      t.integer :query_hash, limit: 8
      t.float :total_time
      t.integer :calls, limit: 8
      t.timestamp :captured_at
    end
  end
  # rubocop:enable Metrics/MethodLength, Rails/CreateTableWithTimestamps
end
