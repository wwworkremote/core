# frozen_string_literal: true

class CreateCareerProfiles < ActiveRecord::Migration[8.0]
  def change
    create_career_profiles_table
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable Metrics/MethodLength
  def create_career_profiles_table
    create_table :career_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.text :resume_text
      t.text :goals
      t.text :skills
      t.string :experience_level

      t.timestamps
    end
  end
  # rubocop:enable Metrics/MethodLength
end
