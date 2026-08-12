# frozen_string_literal: true

class CreatePipelinePrompts < ActiveRecord::Migration[8.1]
  # rubocop:disable Metrics/MethodLength
  def change
    create_table :pipeline_prompts do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.string :stage, null: false
      t.text :body, null: false
      t.text :description
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :pipeline_prompts, :key, unique: true
  end
  # rubocop:enable Metrics/MethodLength
end
