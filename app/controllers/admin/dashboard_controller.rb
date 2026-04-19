# frozen_string_literal: true

module Admin
  class DashboardController < Admin::ApplicationController
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
    end
  end
end
