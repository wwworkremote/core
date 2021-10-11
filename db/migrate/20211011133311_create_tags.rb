# frozen_string_literal: true

class CreateTags < ActiveRecord::Migration[6.1]
  def change
    create_table :tags do |t|
      t.citext :name, unique: true, null: false
      t.citext :slug, null: false

      t.integer :root_tag_id, null: true

      t.datetime :created_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime :updated_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end

    add_index :tags, :name, unique: true
    add_index :tags, :slug, unique: true
  end
end
