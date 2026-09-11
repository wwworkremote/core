# frozen_string_literal: true

class CreateEventStoreEvents < ActiveRecord::Migration[4.2]
  def change
    postgres? ? create_postgres_event_store_tables : create_generic_event_store_tables
    add_event_store_events_indexes
  end

  private

  def postgres?
    ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
  end

  # rubocop:disable-next Metrics/MethodLength, Metrics/AbcSize
  def create_postgres_event_store_tables
    create_table(:event_store_events_in_streams, id: :bigserial, force: false) do |t|
      t.string      :stream,      null: false
      t.integer     :position,    null: true
      t.references  :event,       null: false, type: :uuid
      t.datetime    :created_at,  null: false
    end
    add_index :event_store_events_in_streams, %i[stream position], unique: true
    add_index :event_store_events_in_streams, [:created_at]
    add_index :event_store_events_in_streams, %i[stream event_id], unique: true

    create_table(:event_store_events, id: :bigserial, force: false) do |t|
      t.references  :event,       null: false, type: :uuid
      t.string      :event_type,  null: false
      t.binary      :metadata
      t.binary      :data, null: false
      t.datetime    :created_at,  null: false
      t.datetime    :valid_at,    null: true
    end
  end

  # rubocop:disable-next Metrics/MethodLength, Metrics/AbcSize
  def create_generic_event_store_tables
    create_table(:event_store_events_in_streams, force: false) do |t|
      t.string      :stream,      null: false
      t.integer     :position,    null: true
      t.references  :event,       null: false, type: :string, limit: 36
      t.datetime    :created_at,  null: false, precision: 6
    end
    add_index :event_store_events_in_streams, %i[stream position], unique: true
    add_index :event_store_events_in_streams, [:created_at]
    add_index :event_store_events_in_streams, %i[stream event_id], unique: true

    create_table(:event_store_events, force: false) do |t|
      t.references  :event,       null: false, type: :string, limit: 36
      t.string      :event_type,  null: false
      t.binary      :metadata
      t.binary      :data,        null: false
      t.datetime    :created_at,  null: false, precision: 6
      t.datetime    :valid_at,    null: true,  precision: 6
    end
  end

  def add_event_store_events_indexes
    add_index :event_store_events, :event_id, unique: true
    add_index :event_store_events, :created_at
    add_index :event_store_events, :valid_at
    add_index :event_store_events, :event_type
  end
end
