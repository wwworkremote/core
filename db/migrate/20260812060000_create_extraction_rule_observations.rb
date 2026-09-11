# frozen_string_literal: true

class CreateExtractionRuleObservations < ActiveRecord::Migration[8.1]
  def change
    create_extraction_rule_observations_table
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def create_extraction_rule_observations_table
    create_table :extraction_rule_observations do |t|
      t.string :provider, null: false
      t.string :field_name, null: false
      t.string :candidate_selector
      t.string :learned_selector, null: false
      t.text :element_html
      t.text :parent_html
      t.string :source_url
      t.datetime :created_at, null: false
    end

    add_index :extraction_rule_observations, %i[provider field_name]
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
