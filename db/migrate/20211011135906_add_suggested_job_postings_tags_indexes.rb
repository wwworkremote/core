# frozen_string_literal: true

class AddSuggestedJobPostingsTagsIndexes < ActiveRecord::Migration[6.1]
  def change
    commit_db_transaction
    add_index :job_postings, %i[tags id], algorithm: :concurrently
  end
end
