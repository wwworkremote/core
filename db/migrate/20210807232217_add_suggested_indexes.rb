# frozen_string_literal: true

class AddSuggestedIndexes < ActiveRecord::Migration[6.1]
  def change
    # commit_db_transaction
    # add_index :messages, [:created_at], algorithm: :concurrently
  end
end
