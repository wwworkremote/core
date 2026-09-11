# frozen_string_literal: true

class CreateHackerNewsV0Jobstories < ActiveRecord::Migration[7.0]
  def change
    create_hacker_news_v0_jobstories_table
    add_index :hacker_news_v0_jobstories, :id, unique: true
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable-next Metrics/MethodLength, Metrics/AbcSize
  def create_hacker_news_v0_jobstories_table
    create_table(:hacker_news_v0_jobstories, id: false) do |t|
      t.integer :id, null: false
      t.string :by
      t.integer :score
      t.integer :time
      t.string :title
      t.string :url
      t.text :text
      t.jsonb :data, default: {}, null: false

      t.timestamps
    end
  end
end
