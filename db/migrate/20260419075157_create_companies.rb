# frozen_string_literal: true

class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :slug
      t.string :status

      t.timestamps
    end
    add_index :companies, :slug
  end
end
