# frozen_string_literal: true

class JobBoardsDocumentSignatureIndex < ActiveRecord::Migration[7.0]
  def change
    add_index :job_boards_documents, :signature, unique: true
  end
end
