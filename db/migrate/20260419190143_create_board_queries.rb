# frozen_string_literal: true

class CreateBoardQueries < ActiveRecord::Migration[8.0]
  def change
    create_table :board_queries do |t|
      t.string :board_name
      t.text :terms
      t.boolean :remote
      t.integer :priority
      t.json :query_params

      t.timestamps
    end
  end
end
