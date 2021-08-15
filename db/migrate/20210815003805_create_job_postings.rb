# frozen_string_literal: true

class CreateJobPostings < ActiveRecord::Migration[6.1]
  def change
    create_table :job_postings do |t|
      t.string :signature, null: false, uniq: true

      t.integer :status, default: 0

      t.references :source

      t.string :title
      t.string :body
      t.string :company
      t.string :location
      t.string :external_author_id
      t.string :external_id
      t.datetime :published_at
      t.string :tags, array: true
      t.string :target_url
      t.jsonb :data, default: {}, null: false

      t.datetime :created_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime :updated_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end
  end
end
