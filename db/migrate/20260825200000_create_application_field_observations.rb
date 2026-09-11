class CreateApplicationFieldObservations < ActiveRecord::Migration[7.1]
  def change
    create_table :application_field_observations do |t|
      t.references :user_job_posting, null: false, foreign_key: true
      t.string :field_key, null: false
      t.string :field_label, null: false
      t.string :field_type, null: false
      t.string :question_kind, null: false
      t.string :normalized_prompt, null: false
      t.string :persona_id
      t.string :page_step
      t.string :page_url
      t.jsonb :context, null: false, default: {}
      t.datetime :observed_at, null: false
      t.timestamps
    end
    add_index :application_field_observations, %i[user_job_posting_id field_key], unique: true,
              name: "idx_app_observations_on_app_and_key"
    add_index :application_field_observations, %i[question_kind normalized_prompt],
              name: "idx_app_observations_on_kind_and_prompt"
  end
end
