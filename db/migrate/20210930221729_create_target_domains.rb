# frozen_string_literal: true

class CreateTargetDomains < ActiveRecord::Migration[6.1]
  def change
    create_table :target_domains do |t|
      t.references :job_posting, null: false, foreign_key: true
      t.references :domain, null: false, foreign_key: true

      t.datetime :created_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime :updated_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end
  end
end
