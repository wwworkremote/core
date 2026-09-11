# frozen_string_literal: true

class AddTextFieldToJobstories < ActiveRecord::Migration[7.0]
  def change
    add_column :hacker_news_v0_jobstories, :text, :text
  end
end
