# frozen_string_literal: true

class CreateDomains < ActiveRecord::Migration[6.1]
  def change
    create_table :domains do |t|
      t.citext :name, unique: true, null: false
      t.bigint :root_domain_id, null: true

      t.datetime :created_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime :updated_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end
    add_index :domains, :name, unique: true
  end
end
