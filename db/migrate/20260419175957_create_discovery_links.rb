# frozen_string_literal: true

class CreateDiscoveryLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :discovery_links do |t|
      t.string :board_name
      t.string :url
      t.string :status

      t.timestamps
    end
    add_index :discovery_links, :url
  end
end
