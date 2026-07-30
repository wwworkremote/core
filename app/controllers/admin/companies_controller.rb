# frozen_string_literal: true

class Admin::CompaniesController < Admin::ApplicationController
  def index
    @companies = Company.select("companies.*, count(job_postings.id) as job_postings_count")
                        .left_joins(:job_postings)
                        .group("companies.id")
                        .order(job_postings_count: :desc, name: :asc)
                        .page(params[:page]).per(50)
  end

  def show
    @company = Company.find(params.expect(:id))
    @job_postings = @company.job_postings.recent.page(params[:page]).per(30)
  end

  def toggle_ingestion
    @company = Company.find(params.expect(:id))
    @company.update!(ingestion_enabled: !@company.ingestion_enabled)

    redirect_back_or_to(admin_companies_path, notice: toggle_ingestion_message)
  end

  private

  def toggle_ingestion_message
    return "Ingestion resumed for #{@company.name}." if @company.ingestion_enabled?

    purge_existing_job_postings
    "Ingestion disabled for #{@company.name} and all existing postings have been purged."
  end

  # Cascade: purge all existing jobs for this company
  def purge_existing_job_postings
    @company.job_postings.where.not(status: "purged").find_each(&:purge!)
  end
end
