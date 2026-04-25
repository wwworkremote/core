# frozen_string_literal: true

class Admin::CompaniesController < Admin::ApplicationController
  def index
    @companies = Company.select('companies.*, count(job_postings.id) as job_postings_count')
                        .left_joins(:job_postings)
                        .group('companies.id')
                        .order(job_postings_count: :desc, name: :asc)
                        .page(params[:page]).per(50)
  end

  def show
    @company = Company.find(params[:id])
    @job_postings = @company.job_postings.recent.page(params[:page]).per(30)
  end

  def toggle_ingestion
    @company = Company.find(params[:id])
    @company.update!(ingestion_enabled: !@company.ingestion_enabled)

    if @company.ingestion_enabled?
      message = "Ingestion resumed for #{@company.name}."
    else
      # Cascade: Purge all existing jobs for this company
      @company.job_postings.where.not(status: 'purged').find_each(&:purge!)
      message = "Ingestion disabled for #{@company.name} and all existing postings have been purged."
    end

    redirect_back_or_to(admin_companies_path, notice: message)
  end
end
