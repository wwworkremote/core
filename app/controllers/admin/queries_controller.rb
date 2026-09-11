# frozen_string_literal: true

class Admin::QueriesController < Admin::ApplicationController
  def index
    @queries = JobBoards::Query.order(created_at: :desc).includes(:job_boards_source).page(params[:page]).per(30)
  end

  def show
    @query = JobBoards::Query.find(params.expect(:id))
  end
end
