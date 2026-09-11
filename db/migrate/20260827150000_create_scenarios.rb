# frozen_string_literal: true

class CreateScenarios < ActiveRecord::Migration[8.0]
  # rubocop:disable-next Metrics/AbcSize, Metrics/MethodLength -- one cohesive
  # pair of table definitions; splitting it would obscure the schema, not simplify it.
  def change
    create_table :scenarios do |t|
      t.string :provider, null: false
      t.string :scenario_token, null: false
      t.datetime :started_at, null: false
      t.references :user_job_posting, null: true, foreign_key: true

      t.timestamps
    end
    add_index :scenarios, :scenario_token, unique: true

    create_table :scenario_signatures do |t|
      t.references :scenario, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :value, null: false
      t.string :step
      t.datetime :first_observed_at, null: false

      t.timestamps
    end
    add_index :scenario_signatures, %i[scenario_id kind value], unique: true, name: "idx_scenario_signatures_uniq"
  end
end
