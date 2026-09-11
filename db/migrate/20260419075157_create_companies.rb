# frozen_string_literal: true

class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_companies_table
    add_index :companies, :slug
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def create_companies_table
    create_table :companies do |t|
      t.string :name
      t.string :slug
      t.string :status

      t.timestamps
    end
  end
end
