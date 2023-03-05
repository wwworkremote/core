# frozen_string_literal: true

class CreateHackerNewsV0Jobstories < ActiveRecord::Migration[7.0]
  def change
    create_table(:hacker_news_v0_jobstories, id: false) do |t|
      t.integer :id, null: false
      t.string :by
      t.integer :score
      t.integer :time
      t.string :title
      t.string :url
      t.jsonb :data, default: {}, null: false

      t.timestamps
    end

    add_index :hacker_news_v0_jobstories, :id, unique: true
  end
end
