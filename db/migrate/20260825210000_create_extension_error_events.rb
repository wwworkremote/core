# frozen_string_literal: true

class CreateExtensionErrorEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :extension_error_events do |t|
      t.string :build_version, null: false
      t.string :event_name, null: false
      t.string :phase
      t.string :provider
      t.string :page_host
      t.string :error_name
      t.text :error_message
      t.boolean :recoverable, null: false, default: false
      t.jsonb :context, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :extension_error_events, %i[event_name occurred_at]
  end
end
