# frozen_string_literal: true

class AddTrigramIndexToCompaniesName < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :companies, :name, using: :gin, opclass: :gin_trgm_ops, name: "index_companies_on_name_trgm",
                                 algorithm: :concurrently
  end
end
