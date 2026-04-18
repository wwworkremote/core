class Admin::DashboardController < Admin::ApplicationController
  def index
    @job_postings_count = JobPosting.count
    @sources_count = Source.count
    @active_fetchers_count = JobBoards::Source.where(aasm_state: 'active').count
  end
end
