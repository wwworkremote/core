# frozen_string_literal: true

class DataFetchersController < ApplicationController
  def index
    @fetcher_statuses = DataAcquisitionManager.fetchers.to_h do |f|
      [f[:slug], DataAcquisitionManager.status(f[:slug])]
    end
  end

  def run
    slug = params[:slug]
    force = params[:force] == 'true'

    begin
      result = DataAcquisitionManager.run(slug, force:)

      if result[:success]
        flash[:notice] = "Fetcher #{slug} started successfully."
      else
        flash[:alert] = "Error starting fetcher #{slug}: #{result[:error]}"
      end
    rescue StandardError => e
      flash[:alert] = "Critical error in fetcher #{slug}: #{e.message}"
      Rails.logger.error "[DataFetchersController] Error: #{e.message}\n#{e.backtrace.join("\n")}"
    end

    redirect_to data_fetchers_path
  end

  def run_all_by_type
    type = params[:type]
    fetchers = DataAcquisitionManager.fetchers.select { |f| DataAcquisitionManager::FETCHERS[f[:slug]][:type] == type }

    begin
      fetchers.each do |f|
        DataAcquisitionManager.run(f[:slug], force: false)
      end
      flash[:notice] = "Triggered all #{type} pipelines."
    rescue StandardError => e
      flash[:alert] = "Error triggering pipelines: #{e.message}"
    end

    redirect_to data_fetchers_path
  end

  def audit
    JobBoards::AuditJob.perform_later
    flash[:notice] = 'Audit and repair job has been enqueued.'
    redirect_to data_fetchers_path
  end

  def enrich
    JobBoards::ContentEnrichmentJob.perform_later
    flash[:notice] = 'Content enrichment pipeline triggered.'
    redirect_to data_fetchers_path
  end
end
