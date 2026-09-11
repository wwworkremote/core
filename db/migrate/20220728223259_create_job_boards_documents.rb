# frozen_string_literal: true

class CreateJobBoardsDocuments < ActiveRecord::Migration[7.0]
  def change
    create_job_boards_documents_table
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable-next Metrics/MethodLength, Metrics/AbcSize
  def create_job_boards_documents_table
    create_table(:job_boards_documents, id: :uuid) do |t|
      t.integer :source_id, null: false
      t.integer :job_boards_query_id, null: false
      t.text :document, default: "", null: false
      t.string :signature
      t.string :aasm_state

      t.datetime "created_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.datetime "updated_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    end
  end
end
