# frozen_string_literal: true

class CreateExperienceHighlights < ActiveRecord::Migration[8.0]
  def change
    create_experience_highlights_table
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def create_experience_highlights_table
    create_table :experience_highlights do |t|
      t.references :work_experience, null: false, foreign_key: true
      t.string :label
      t.text :text

      t.timestamps
    end
  end
end
