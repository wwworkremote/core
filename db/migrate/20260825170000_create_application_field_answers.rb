# frozen_string_literal: true

class CreateApplicationFieldAnswers < ActiveRecord::Migration[8.1]
  # One cohesive table definition; splitting it would obscure the schema.
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def change
    create_table :application_field_answers do |t|
      t.references :user_job_posting, null: false, foreign_key: true
      t.string :field_key, null: false
      t.string :field_label, null: false
      t.string :field_type, null: false
      t.text :answer, null: false
      t.string :answer_source, null: false
      t.string :page_url
      t.datetime :provided_at, null: false
      t.timestamps
    end

    add_index :application_field_answers, %i[user_job_posting_id field_key], unique: true,
                                                                             name: "idx_app_fields_on_app_and_key"
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
