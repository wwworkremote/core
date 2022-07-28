# frozen_string_literal: true

class CreateJobBoardsSources < ActiveRecord::Migration[7.0]
  def change
    create_table(:job_boards_sources) do |t|
      t.string :name, null: false
      t.string :slug

      t.jsonb :data, default: {}, null: false
      t.string :aasm_state

      t.datetime 'created_at', precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime 'updated_at', precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end

    add_index :job_boards_sources, :slug, unique: true
  end
end
