# frozen_string_literal: true

class CreateReferenceScenarios < ActiveRecord::Migration[8.0]
  # rubocop:disable-next Metrics/MethodLength -- one cohesive pointer-table definition.
  def change
    create_table :reference_scenarios do |t|
      t.string :provider, null: false
      t.references :scenario, null: false, foreign_key: true, index: false

      t.timestamps
    end
    add_index :reference_scenarios, :provider, unique: true
    add_index :reference_scenarios, :scenario_id, unique: true
  end
end
