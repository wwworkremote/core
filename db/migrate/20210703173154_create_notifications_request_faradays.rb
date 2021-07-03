# frozen_string_literal: true

class CreateNotificationsRequestFaradays < ActiveRecord::Migration[6.1]
  def change
    create_table :notifications_request_faradays do |t|
      t.string :signature, unique: true, null: false
      t.jsonb :event, default: {}, null: false
      t.jsonb :payload, default: {}, null: false

      t.datetime :created_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime :updated_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end

    add_index :notifications_request_faradays, :signature, unique: true
  end
end
