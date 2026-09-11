# frozen_string_literal: true

class CreateBoardQueries < ActiveRecord::Migration[8.0]
  def change
    create_board_queries_table
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable Metrics/MethodLength
  def create_board_queries_table
    create_table :board_queries do |t|
      t.string :board_name
      t.text :terms
      t.boolean :remote, default: false, null: false
      t.integer :priority
      t.json :query_params

      t.timestamps
    end
  end
  # rubocop:enable Metrics/MethodLength
end
