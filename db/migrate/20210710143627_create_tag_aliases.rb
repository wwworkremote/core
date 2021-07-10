# frozen_string_literal: true

class CreateTagAliases < ActiveRecord::Migration[6.1]
  def change
    create_table :tag_aliases do |t|
      t.references :tag, null: true, foreign_key: true
      t.citext :name, null: false

      t.datetime :created_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime :updated_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end
    add_index :tag_aliases, :name, unique: true
  end
end
