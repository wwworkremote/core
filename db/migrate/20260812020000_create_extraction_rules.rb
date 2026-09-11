# frozen_string_literal: true

# rubocop:disable-next Metrics/MethodLength
class CreateExtractionRules < ActiveRecord::Migration[8.1]
  def change
    create_table :extraction_rules do |t|
      t.string :provider, null: false
      t.string :field_name, null: false
      t.string :selector, null: false
      t.text :sample_html
      t.string :source_url

      t.timestamps
    end

    add_index :extraction_rules, %i[provider field_name], unique: true
  end
end
