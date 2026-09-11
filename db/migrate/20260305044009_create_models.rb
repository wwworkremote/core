# frozen_string_literal: true

class CreateModels < ActiveRecord::Migration[8.0]
  # Column and index list is one cohesive table definition -- splitting it
  # further would obscure the schema, not simplify it.
  # rubocop:disable-next Metrics/MethodLength, Metrics/AbcSize
  def change
    create_table :models do |t|
      t.string :model_id, null: false
      t.string :name, null: false
      t.string :provider, null: false
      t.string :family
      t.datetime :model_created_at
      t.integer :context_window
      t.integer :max_output_tokens
      t.date :knowledge_cutoff

      t.jsonb :modalities, default: {}
      t.jsonb :capabilities, default: []
      t.jsonb :pricing, default: {}
      t.jsonb :metadata, default: {}

      t.timestamps

      t.index %i[provider model_id], unique: true
      t.index :provider
      t.index :family

      t.index :capabilities, using: :gin
      t.index :modalities, using: :gin
    end
  end
end
