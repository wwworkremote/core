# frozen_string_literal: true

class CreateEventStoreEvents < ActiveRecord::Migration[4.2]
  def change
    postgres =
      ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
    if postgres
      create_table(:event_store_events_in_streams, id: :bigserial, force: false) do |t|
        t.string      :stream,      null: false
        t.integer     :position,    null: true
        t.references  :event,       null: false, type: :uuid
        t.datetime    :created_at,  null: false
      end
      add_index :event_store_events_in_streams, %i[stream position], unique: true, algorithm: :concurrently
      add_index :event_store_events_in_streams, [:created_at], algorithm: :concurrently
      add_index :event_store_events_in_streams, %i[stream event_id], unique: true, algorithm: :concurrently

      create_table(:event_store_events, id: :bigserial, force: false) do |t|
        t.references  :event,       null: false, type: :uuid
        t.string      :event_type,  null: false
        t.jsonb      :metadata
        t.jsonb      :data, null: false
        t.datetime    :created_at,  null: false
        t.datetime    :valid_at,    null: true
      end
    else
      create_table(:event_store_events_in_streams, force: false) do |t|
        t.string      :stream,      null: false
        t.integer     :position,    null: true
        t.references  :event,       null: false, type: :string, limit: 36
        t.datetime    :created_at,  null: false, precision: 6
      end
      add_index :event_store_events_in_streams, %i[stream position], unique: true, algorithm: :concurrently
      add_index :event_store_events_in_streams, [:created_at], algorithm: :concurrently
      add_index :event_store_events_in_streams, %i[stream event_id], unique: true, algorithm: :concurrently

      create_table(:event_store_events, force: false) do |t|
        t.references  :event,       null: false, type: :string, limit: 36
        t.string      :event_type,  null: false
        t.binary      :metadata
        t.binary      :data,        null: false
        t.datetime    :created_at,  null: false, precision: 6
        t.datetime    :valid_at,    null: true,  precision: 6
      end
    end
    add_index :event_store_events, :event_id, unique: true, algorithm: :concurrently
    add_index :event_store_events, :created_at, algorithm: :concurrently
    add_index :event_store_events, :valid_at, algorithm: :concurrently
    add_index :event_store_events, :event_type, algorithm: :concurrently
  end
end
