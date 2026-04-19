# frozen_string_literal: true

class DataFetchersController < ApplicationController
  def index
    @fetchers = DataAcquisitionManager.fetchers.map do |f|
      DataAcquisitionManager.status(f[:slug])
    end
  end

  def run
    slug = params[:slug]
    force = params[:force] == 'true'

    result = DataAcquisitionManager.run(slug, force:)

    if result[:success]
      flash[:notice] = "Fetcher #{slug} started successfully."
    else
      flash[:alert] = "Error starting fetcher #{slug}: #{result[:error]}"
    end

    redirect_to data_fetchers_path
  end

  def run_all_by_type
    type = params[:type]
    fetchers = DataAcquisitionManager.fetchers.select { |f| DataAcquisitionManager::FETCHERS[f[:slug]][:type] == type }
    
    fetchers.each do |f|
      DataAcquisitionManager.run(f[:slug])
    end

    flash[:notice] = "Triggered all #{type} pipelines."
    redirect_to data_fetchers_path
  end

  def audit
    JobBoards::AuditJob.perform_later
    flash[:notice] = 'Audit and repair job has been enqueued.'
    redirect_to data_fetchers_path
  end
end
