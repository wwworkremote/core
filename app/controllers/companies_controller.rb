# frozen_string_literal: true

class CompaniesController < ApplicationController
  def index; end

  def show
    @company = Company.includes(:job_postings, :company_pipeline_steps).find(params[:id])
  end
end
