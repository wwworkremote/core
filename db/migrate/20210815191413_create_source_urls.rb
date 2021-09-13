# frozen_string_literal: true

class CreateSourceUrls < ActiveRecord::Migration[6.1]
  def change
    create_table :source_urls do |t|
      t.string :url, null: false, uniq: true

      t.string :protocol
      t.string :host
      t.string :path, array: true, default: [], null: false

      t.jsonb :querystring, default: {}, null: false

      t.datetime :created_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime :updated_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end
  end
end
