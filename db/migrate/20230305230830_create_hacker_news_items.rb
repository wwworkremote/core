# frozen_string_literal: true

class CreateHackerNewsItems < ActiveRecord::Migration[7.0]
  def change
    create_hacker_news_items_table
    add_index :hacker_news_items, :id, unique: true
    add_index :hacker_news_items, :schema
    add_index :hacker_news_items, :state
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable Metrics/MethodLength
  def create_hacker_news_items_table
    create_table(:hacker_news_items, id: false) do |t|
      t.integer :id, null: false
      t.integer :schema, null: false, default: 0
      t.integer :state, null: false, default: 0

      t.timestamps
    end
  end
  # rubocop:enable Metrics/MethodLength
end
