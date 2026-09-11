# frozen_string_literal: true

class AddDataToHackerNewsItem < ActiveRecord::Migration[7.0]
  def change
    add_column :hacker_news_items, :data, :jsonb, default: {}
  end
end
