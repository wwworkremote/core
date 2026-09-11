# frozen_string_literal: true

class CreateJobExperiences < ActiveRecord::Migration[8.0]
  def change
    create_job_experiences_table
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def create_job_experiences_table
    create_table :job_experiences do |t|
      t.references :career_profile, null: false, foreign_key: true
      t.string :title
      t.string :company
      t.date :start_date
      t.date :end_date
      t.boolean :current, default: false, null: false
      t.text :description

      t.timestamps
    end
  end
end
