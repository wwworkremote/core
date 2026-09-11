# frozen_string_literal: true

class CreateLLMMessages < ActiveRecord::Migration[8.0]
  def change
    create_llm_messages_table
    add_index :llm_messages, :role
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable-next Metrics/MethodLength, Metrics/AbcSize
  def create_llm_messages_table
    create_table :llm_messages do |t|
      t.string :role, null: false
      t.text :content
      t.json :content_raw
      t.text :thinking_text
      t.text :thinking_signature
      t.integer :thinking_tokens
      t.integer :input_tokens
      t.integer :output_tokens
      t.integer :cached_tokens
      t.integer :cache_creation_tokens
      t.timestamps
    end
  end
end
