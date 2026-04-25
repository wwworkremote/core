# frozen_string_literal: true

class Admin::DocumentsController < Admin::ApplicationController
  def index
    @documents = JobBoards::Document.order(created_at: :desc).includes(:job_boards_source,
                                                                       :job_boards_query).page(params[:page]).per(30)
  end

  def show
    @document = JobBoards::Document.find(params[:id])
  end

  def destroy
    @document = JobBoards::Document.find(params[:id])
    @document.destroy
    redirect_to admin_documents_path, notice: "Document was successfully deleted."
  end
end
