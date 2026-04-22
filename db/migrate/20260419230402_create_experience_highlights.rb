# frozen_string_literal: true

class CreateExperienceHighlights < ActiveRecord::Migration[8.0]
  def change
    create_table :experience_highlights do |t|
      t.references :work_experience, null: false, foreign_key: true
      t.string :label
      t.text :text

      t.timestamps
    end
  end
end
