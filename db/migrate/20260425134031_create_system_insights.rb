# frozen_string_literal: true

class CreateSystemInsights < ActiveRecord::Migration[8.0]
  def change
    create_system_insights_table
    add_system_insights_indexes
  end

  private

  # Already applied -- editing the column list here wouldn't retroactively
  # add a NOT NULL constraint to the live column, only misrepresent this
  # migration's history. A real fix would be a new migration.
  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable Rails/ThreeStateBooleanColumn, Metrics/MethodLength, Metrics/AbcSize
  def create_system_insights_table
    create_table :system_insights do |t|
      t.integer :tool
      t.integer :severity
      t.text :message
      t.string :file_path
      t.integer :line_number
      t.text :context
      t.boolean :active, default: true
      t.vector :embedding, limit: 3584

      t.timestamps
    end
  end
  # rubocop:enable Rails/ThreeStateBooleanColumn, Metrics/MethodLength, Metrics/AbcSize

  def add_system_insights_indexes
    add_index :system_insights, :file_path
    add_index :system_insights, :active
  end
end
