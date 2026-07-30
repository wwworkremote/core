# frozen_string_literal: true

class CreateDiscoveryLinks < ActiveRecord::Migration[8.0]
  def change
    create_discovery_links_table
    add_index :discovery_links, :url
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable Metrics/MethodLength
  def create_discovery_links_table
    create_table :discovery_links do |t|
      t.string :board_name
      t.string :url
      t.string :status

      t.timestamps
    end
  end
  # rubocop:enable Metrics/MethodLength
end
