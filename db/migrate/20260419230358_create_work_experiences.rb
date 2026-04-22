# frozen_string_literal: true

class CreateWorkExperiences < ActiveRecord::Migration[8.0]
  def change
    create_table :work_experiences do |t|
      t.references :career_profile, null: false, foreign_key: true
      t.string :company_name
      t.string :location
      t.string :title
      t.string :employment_type
      t.date :start_date
      t.date :end_date
      t.text :context
      t.text :description
      t.text :summary
      t.text :action
      t.text :impact
      t.jsonb :scope

      t.timestamps
    end
  end
end
