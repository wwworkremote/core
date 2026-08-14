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
    @company.ingestion_enabled? ? @company.disable_ingestion! : @company.update!(ingestion_enabled: true)

    redirect_back_or_to(admin_companies_path, notice: toggle_ingestion_message)
  end

  def mark_not_interested
    @company = Company.find(params.expect(:id))
    @company.mark_not_interested!

    redirect_back_or_to(admin_companies_path, notice: not_interested_message)
  end

  private

  def toggle_ingestion_message
    return "Ingestion resumed for #{@company.name}." if @company.ingestion_enabled?

    "Ingestion disabled for #{@company.name} and all existing postings have been purged."
  end

  def not_interested_message
    "#{@company.name} marked not interested. Open postings ignored; future postings will auto-ignore."
  end
end
