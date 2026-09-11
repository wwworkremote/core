# frozen_string_literal: true

class CreateToolCalls < ActiveRecord::Migration[8.0]
  def change
    create_tool_calls_table
    add_index :tool_calls, :tool_call_id, unique: true
    add_index :tool_calls, :name
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def create_tool_calls_table
    create_table :tool_calls do |t|
      t.string :tool_call_id, null: false
      t.string :name, null: false
      t.string :thought_signature

      t.jsonb :arguments, default: {}

      t.timestamps
    end
  end
end
