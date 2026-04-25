# frozen_string_literal: true

class Admin::DashboardController < Admin::ApplicationController
  def index
    @job_postings_count = JobPosting.count
    @documents_count = JobBoards::Document.count
    @sources_count = JobBoards::Source.count
    @domains_count = Domain.count
    @email_records_count = EmailImportRecord.count
    @models_count = Model.count
    @visits_count = Ahoy::Visit.count
    @events_count = Ahoy::Event.count
    @active_fetchers_count = @sources_count

    @pipelines_paused = SystemSetting.paused?

    # Recent ingestion for ticker feed (initial load)
    @recent_ingestions = JobPosting.includes(:source).order(created_at: :desc).limit(10)
  end

  def toggle_pause
    if SystemSetting.paused?
      SystemSetting.resume!
      flash[:notice] = 'Pipelines resumed.'
    else
      SystemSetting.pause!
      flash[:alert] = 'Emergency Brake Engaged: Pipelines paused.'
    end
    redirect_to admin_root_path
  end
end
