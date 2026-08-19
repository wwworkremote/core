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
    flip_exclusion(source)
    redirect_to admin_source_path(source)
  end

  private

  # New postings self-exclude via JobBoards::QualityFilter#excluded_source?
  # going forward; sweep existing untouched/low-quality postings from this
  # source the same way "Run Audit" already does for everything else.
  def flip_exclusion(source)
    source.update!(excluded_from_results: !source.excluded_from_results)
    JobBoards::AuditJob.perform_later if source.excluded_from_results?
  end
end
