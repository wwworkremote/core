# frozen_string_literal: true

class CreateSourcesSourceUrls < ActiveRecord::Migration[6.1]
  def change
    create_table :sources_source_urls do |t|
      t.references :source, null: false, foreign_key: true
      t.references :source_url, null: false, foreign_key: true

      t.timestamps
    end
  end
end
