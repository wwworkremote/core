# frozen_string_literal: true

class DataFetchersController < ApplicationController
  def index
    @fetcher_statuses = DataAcquisitionManager.fetchers.to_h do |f|
      [f[:slug], DataAcquisitionManager.status(f[:slug])]
    end
  end

  def run
    slug = params[:slug]
    run_fetcher(slug, force: params[:force] == "true")
    redirect_to data_fetchers_path
  end

  def run_all_by_type
    type = params[:type]
    run_fetchers_by_type(type)
    redirect_to data_fetchers_path
  end

  def audit
    JobBoards::AuditJob.perform_later
    flash[:notice] = "Audit and repair job has been enqueued."
    redirect_to data_fetchers_path
  end

  def enrich
    JobBoards::ContentEnrichmentJob.perform_later
    flash[:notice] = "Content enrichment pipeline triggered."
    redirect_to data_fetchers_path
  end

  private

  def run_fetcher(slug, force:)
    result = DataAcquisitionManager.run(slug, force: force)
    apply_run_result(slug, result)
  rescue StandardError => e
    handle_run_error(slug, e)
  end

  def handle_run_error(slug, error)
    flash[:alert] = "Critical error in fetcher #{slug}: #{error.message}"
    Rails.logger.error "[DataFetchersController] Error: #{error.message}\n#{error.backtrace.join("\n")}"
  end

  def apply_run_result(slug, result)
    if result[:success]
      flash[:notice] = "Fetcher #{slug} started successfully."
    else
      flash[:alert] = "Error starting fetcher #{slug}: #{result[:error]}"
    end
  end

  def run_fetchers_by_type(type)
    trigger_all(fetchers_of_type(type))
    flash[:notice] = "Triggered all #{type} pipelines."
  rescue StandardError => e
    flash[:alert] = "Error triggering pipelines: #{e.message}"
  end

  def trigger_all(fetchers)
    fetchers.each { |f| DataAcquisitionManager.run(f[:slug], force: false) }
  end

  def fetchers_of_type(type)
    DataAcquisitionManager.fetchers.select { |f| Ingestion::AdapterRegistry.get(f[:slug])[:type] == type }
  end
end
