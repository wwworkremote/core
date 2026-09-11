# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
# What one Reference Comparison run inferred: a single drift or coverage gap
# (ADR 009). Immutable. locator is the stable string identifying what diverged.
class CreateComparisonFindings < ActiveRecord::Migration[8.1]
  def change
    create_table :comparison_findings do |t|
      t.references :reference_comparison, null: false, foreign_key: true
      t.string :category, null: false
      t.string :dimension, null: false
      t.string :locator, null: false
      t.jsonb :detail, null: false, default: {}
      t.bigint :suggested_disposition_id
      t.timestamps
    end
    add_index :comparison_findings, %i[dimension locator]
  end
end
# rubocop:enable Metrics/MethodLength
