# frozen_string_literal: true

class AddIngestionEnabledToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :ingestion_enabled, :boolean, default: true, null: false
  end
end
