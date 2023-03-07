# frozen_string_literal: true

class CreateHackerNewsItems < ActiveRecord::Migration[7.0]
  def change
    create_table(:hacker_news_items, id: false) do |t|
      t.integer :id, null: false
      t.integer :schema, null: false, default: 0
      t.integer :state, null: false, default: 0

      t.timestamps
    end

    add_index :hacker_news_items, :id, unique: true
    add_index :hacker_news_items, :schema
    add_index :hacker_news_items, :state
  end
end
