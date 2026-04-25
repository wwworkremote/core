# frozen_string_literal: true

class Admin::SourcesController < Admin::ApplicationController
  def index
    @sources = JobBoards::Source.order(created_at: :desc).page(params[:page]).per(30)
  end

  def show
    @source = JobBoards::Source.find(params[:id])
  end
end
