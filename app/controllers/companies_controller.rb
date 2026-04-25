# frozen_string_literal: true

class CompaniesController < ApplicationController
  def index
    @companies = Company.includes(:job_postings)
                        .select('companies.*, count(job_postings.id) as job_postings_count')
                        .left_joins(:job_postings)
                        .group('companies.id')
                        .order(job_postings_count: :desc, name: :asc)
                        .page(params[:page]).per(24)
  end

  def show
    @company = Company.includes(:job_postings, :company_pipeline_steps).find(params[:id])
  end
end
