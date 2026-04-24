# frozen_string_literal: true

module Admin
  class CompaniesController < Admin::ApplicationController
    def index
      @companies = Company.select('companies.*, count(job_postings.id) as job_postings_count')
                          .left_joins(:job_postings)
                          .group('companies.id')
                          .order('job_postings_count DESC, name ASC')
                          .page(params[:page]).per(50)
    end

    def show
      @company = Company.find(params[:id])
      @job_postings = @company.job_postings.recent.page(params[:page]).per(30)
    end

    def toggle_ingestion
      @company = Company.find(params[:id])
      @company.update!(ingestion_enabled: !@company.ingestion_enabled)

      if !@company.ingestion_enabled?
        # Cascade: Purge all existing jobs for this company
        @company.job_postings.where.not(status: 'purged').find_each(&:purge!)
        message = "Ingestion disabled for #{@company.name} and all existing postings have been purged."
      else
        message = "Ingestion resumed for #{@company.name}."
      end

      redirect_back fallback_location: admin_companies_path, notice: message
    end
  end
end
