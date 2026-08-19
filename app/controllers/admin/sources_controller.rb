# frozen_string_literal: true

class Admin::SourcesController < Admin::ApplicationController
  def index
    @sources = JobBoards::Source.order(created_at: :desc).page(params[:page]).per(30)
  end

  def show
    @source = JobBoards::Source.find(params.expect(:id))
  end

  def toggle_ingestion
    source = JobBoards::Source.find(params.expect(:id))
    source.update!(ingestion_paused: !source.ingestion_paused)
    redirect_to admin_source_path(source)
  end

  def toggle_exclusion
    source = JobBoards::Source.find(params.expect(:id))
    source.update!(excluded_from_results: !source.excluded_from_results)
    redirect_to admin_source_path(source)
  end
end
