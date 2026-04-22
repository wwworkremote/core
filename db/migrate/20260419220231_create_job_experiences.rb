# frozen_string_literal: true

class CreateJobExperiences < ActiveRecord::Migration[8.0]
  def change
    create_table :job_experiences do |t|
      t.references :career_profile, null: false, foreign_key: true
      t.string :title
      t.string :company
      t.date :start_date
      t.date :end_date
      t.boolean :current
      t.text :description

      t.timestamps
    end
  end
end
