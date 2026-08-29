# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
# One immutable row per Reference Comparison run (ADR 009), including failed and
# no-reference attempts -- operational diagnosis matters.
class CreateReferenceComparisons < ActiveRecord::Migration[8.1]
  def change
    create_table :reference_comparisons do |t|
      t.references :guided_session, null: false, foreign_key: true
      t.references :scenario, null: false, foreign_key: true
      t.references :reference_scenario, null: true, foreign_key: true
      t.string :provider, null: false
      t.string :comparison_rules_version, null: false
      t.string :outcome, null: false
      t.string :trigger, null: false
      t.string :error
      t.jsonb :coverage, null: false, default: {}
      t.datetime :ran_at, null: false
      t.timestamps
    end
    add_index :reference_comparisons, %i[provider reference_scenario_id]
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
