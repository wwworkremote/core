# frozen_string_literal: true

class AddMissingIndexesToJobBoardsTables < ActiveRecord::Migration[7.2]
  def change
    add_index :job_boards_documents, :source_id unless index_exists?(:job_boards_documents, :source_id)
    add_index :job_boards_documents, :job_boards_query_id unless index_exists?(:job_boards_documents, :job_boards_query_id)
    add_index :job_boards_queries, :source_id unless index_exists?(:job_boards_queries, :source_id)
  end
end
