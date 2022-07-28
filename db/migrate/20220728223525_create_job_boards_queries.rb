# frozen_string_literal: true

class CreateJobBoardsQueries < ActiveRecord::Migration[7.0]
  def change
    create_table :job_boards_queries do |t|
      t.integer :source_id, null: false
      t.jsonb :data, default: {}, null: false
      t.string :aasm_state

      t.datetime 'created_at', precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime 'updated_at', precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end
  end
end
