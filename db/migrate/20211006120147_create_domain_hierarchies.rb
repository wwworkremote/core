# frozen_string_literal: true

class CreateDomainHierarchies < ActiveRecord::Migration[6.1]
  def change
    create_view :domain_hierarchies, materialized: true

    add_index :domain_hierarchies, :id, unique: true, algorithm: :concurrently
  end
end
