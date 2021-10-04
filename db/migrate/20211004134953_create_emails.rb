# frozen_string_literal: true

class CreateEmails < ActiveRecord::Migration[6.1]
  def change
    create_table :emails do |t|
      t.citext :address, unique: true, null: false

      t.datetime :created_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime :updated_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end
    add_index :emails, :address, unique: true
  end
end
