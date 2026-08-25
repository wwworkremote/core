# frozen_string_literal: true

class CreateApplicationFieldMappings < ActiveRecord::Migration[8.1]
  def change
    create_table :application_field_mappings do |t|
      t.references :user_job_posting, null: false, foreign_key: true
      t.references :application_field_answer, null: true, foreign_key: true
      t.string :field_key, null: false
      t.string :field_label, null: false
      t.string :semantic_key, null: false
      t.string :semantic_label
      t.string :source_kind, null: false
      t.string :provider
      t.string :page_step
      t.string :page_url
      t.string :page_title
      t.string :element_fingerprint
      t.jsonb :element_descriptor, null: false, default: {}
      t.jsonb :context, null: false, default: {}
      t.datetime :mapped_at, null: false
      t.timestamps
    end

    add_index :application_field_mappings,
              %i[user_job_posting_id field_key semantic_key],
              name: "idx_app_field_mappings_on_application_field_semantic"
  end
end
