# frozen_string_literal: true

class JobPostingsController < ApplicationController
  def index
    assign_filter_params
    @job_postings = filtered_job_postings.page(params[:page]).per(20)
  end

  def show
    @job_posting = JobPosting.includes(:contacts).find(params.expect(:id))
    ahoy.track "Viewed Job Posting", job_posting_id: @job_posting.id, title: @job_posting.title
  end

  private

  def assign_filter_params
    @query = params[:q]
    @company = params[:company]
    @source_id = params[:source_id]
    @tier = params[:tier]
  end

  def filtered_job_postings
    scope = base_job_postings
    scope = scope.where(company_name: @company) if @company.present?
    scope = scope.where(source_id: @source_id) if @source_id.present?
    apply_query_and_tier(scope)
  end

  def apply_query_and_tier(scope)
    scope = scope.search(@query) if @query.present?
    scope = scope.management_tier if @tier == "management"
    scope
  end

  def base_job_postings
    scope = JobPosting.recent.includes(source: :origin)
    scope = scope.where.not(status: %w[ignored purged expired]) if params[:status].blank?
    scope
  end
end
