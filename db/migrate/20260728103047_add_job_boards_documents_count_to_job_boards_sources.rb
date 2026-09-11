# frozen_string_literal: true

class AddJobBoardsDocumentsCountToJobBoardsSources < ActiveRecord::Migration[8.0]
  def up
    add_column :job_boards_sources, :job_boards_documents_count, :integer, default: 0, null: false

    JobBoards::Source.reset_column_information
    JobBoards::Source.find_each do |source|
      JobBoards::Source.reset_counters(source.id, :job_boards_documents)
    end
  end

  def down
    remove_column :job_boards_sources, :job_boards_documents_count
  end
end
