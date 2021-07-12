# frozen_string_literal: true

class CreateMoments < ActiveRecord::Migration[6.1]
  def change
    create_table :moments do |t|
      t.integer :cleek
      t.datetime :cleeked_at
      t.integer :value
      t.datetime :lbound
      t.integer :lbound_week_value
      t.datetime :lbound_week
      t.integer :lbound_day_value
      t.datetime :lbound_day
      t.integer :lbound_hour_value
      t.datetime :lbound_hour
      t.datetime :rbound

      t.datetime :created_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end
  end
end
