class CreateCareerProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :career_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.text :resume_text
      t.text :goals
      t.text :skills
      t.string :experience_level

      t.timestamps
    end
  end
end
