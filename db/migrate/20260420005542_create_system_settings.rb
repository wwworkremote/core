# frozen_string_literal: true

class CreateSystemSettings < ActiveRecord::Migration[8.0]
  def change
    create_system_settings_table
    add_index :system_settings, :key
  end

  private

  def create_system_settings_table
    create_table :system_settings do |t|
      t.string :key
      t.string :value

      t.timestamps
    end
  end
end
