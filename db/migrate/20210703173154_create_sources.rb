# frozen_string_literal: true

class CreateSources < ActiveRecord::Migration[6.1]
  def change
    create_table :sources do |t|
      t.string :signature, unique: true, null: false
      t.jsonb :event, default: {}, null: false
      t.jsonb :payload, default: {}, null: false
      t.bigint :status, default: 0, limit: 8

      t.datetime :created_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime :updated_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end

    add_index :sources, :signature, unique: true
  end
end
