# frozen_string_literal: true

class AddIntelligenceToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :glassdoor_data, :jsonb
    add_column :companies, :sentiment_score, :float
    add_column :companies, :disposition, :string
    add_column :companies, :toxic_culture_flag, :boolean, default: false, null: false
  end
end
