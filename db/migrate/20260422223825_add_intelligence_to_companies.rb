# frozen_string_literal: true

class AddIntelligenceToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_company_intelligence_columns
  end

  private

  # Column list is one cohesive change_table block -- splitting it
  # further would obscure it, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def add_company_intelligence_columns
    change_table :companies, bulk: true do |t|
      t.jsonb :glassdoor_data
      t.float :sentiment_score
      t.string :disposition
      t.boolean :toxic_culture_flag, default: false, null: false
    end
  end
end
