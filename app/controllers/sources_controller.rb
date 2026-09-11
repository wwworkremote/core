# frozen_string_literal: true

class SourcesController < ApplicationController
  # The index composes the query from independent URL filters.
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def index
    scope = filtered_sources
    @sources = scope.order(job_boards_documents_count: :desc, name: :asc).page(params[:page]).per(24)
  end

  def show
    @source = JobBoards::Source.find(params.expect(:id))
  end

  private

  def filtered_sources
    scope = JobBoards::Source.all
    @query = params[:q].to_s.strip
    if @query.present?
      pattern = "%#{JobBoards::Source.sanitize_sql_like(@query)}%"
      scope = scope.where("name ILIKE :q OR slug ILIKE :q", q: pattern)
    end
    scope = scope.where(ingestion_paused: false) if params[:active] == "1"
    scope = scope.where(excluded_from_results: true) if params[:excluded] == "1"
    scope
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
