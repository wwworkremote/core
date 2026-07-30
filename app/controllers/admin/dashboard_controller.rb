# frozen_string_literal: true

class Admin::DashboardController < Admin::ApplicationController
  def index
    assign_counts
    @pipelines_paused = SystemSetting.paused?
    # Recent ingestion for ticker feed (initial load)
    @recent_ingestions = JobPosting.includes(:source).order(created_at: :desc).limit(10)
  end

  def toggle_pause
    SystemSetting.paused? ? resume_pipelines : pause_pipelines
    redirect_to admin_root_path
  end

  private

  def assign_counts
    assign_ingestion_counts
    assign_analytics_counts
  end

  def assign_ingestion_counts
    @job_postings_count = JobPosting.count
    @documents_count = JobBoards::Document.count
    @domains_count = Domain.count
    assign_source_counts
    assign_registry_counts
  end

  def assign_source_counts
    @sources_count = JobBoards::Source.count
    @active_fetchers_count = @sources_count
  end

  def assign_registry_counts
    @email_records_count = EmailImportRecord.count
    @models_count = Model.count
  end

  def assign_analytics_counts
    @visits_count = Ahoy::Visit.count
    @events_count = Ahoy::Event.count
  end

  def resume_pipelines
    SystemSetting.resume!
    flash[:notice] = "Pipelines resumed."
  end

  def pause_pipelines
    SystemSetting.pause!
    flash[:alert] = "Emergency Brake Engaged: Pipelines paused."
  end
end
