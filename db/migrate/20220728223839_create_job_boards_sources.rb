# frozen_string_literal: true

class CreateJobBoardsSources < ActiveRecord::Migration[7.0]
  def change
    create_job_boards_sources_table
    add_index :job_boards_sources, :slug, unique: true
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable Metrics/MethodLength
  def create_job_boards_sources_table
    create_table(:job_boards_sources) do |t|
      t.string :name, null: false
      t.string :slug

      t.jsonb :data, default: {}, null: false
      t.string :aasm_state

      t.datetime "created_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.datetime "updated_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    end
  end
  # rubocop:enable Metrics/MethodLength
end
