# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Documents" do
  describe "GET /admin/documents" do
    it "lists documents newest first" do
      # Longer, collision-resistant signatures -- "older"/"newer" are
      # substrings of common page text (e.g. the command palette's
      # `placeholder=` attribute contains "older"), which broke this
      # exact assertion once (TASK-77).
      older = create(:job_boards_document, signature: "older-doc-sig", created_at: 1.day.ago)
      newer = create(:job_boards_document, signature: "newer-doc-sig")

      get admin_documents_path

      expect(response).to be_successful
      newer_index = response.body.index(newer.signature)
      older_index = response.body.index(older.signature)
      expect(newer_index).to be < older_index
    end
  end

  describe "GET /admin/documents/:id" do
    it "shows the document" do
      document = create(:job_boards_document)

      get admin_document_path(document)

      expect(response).to be_successful
    end
  end

  describe "DELETE /admin/documents/:id" do
    it "deletes the document and redirects with a notice" do
      document = create(:job_boards_document)

      delete admin_document_path(document)

      expect(JobBoards::Document.exists?(document.id)).to be false
      expect(response).to redirect_to(admin_documents_path)
      expect(flash[:notice]).to eq("Document was successfully deleted.")
    end
  end
end
