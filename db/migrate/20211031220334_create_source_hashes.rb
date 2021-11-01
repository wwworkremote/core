# frozen_string_literal: true

class CreateSourceHashes < ActiveRecord::Migration[6.1]
  def change
    create_table :source_hashes, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.uuid :source_id, unique: true
      t.text :value, null: false, unique: true

      t.datetime :created_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime :updated_at, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end

    add_index :source_hashes, %i[source_id value], unique: true
  end
end
