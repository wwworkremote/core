# frozen_string_literal: true

class JobPostingsController < ApplicationController
  def index
    @query = params[:q]
    @company = params[:company]
    @source_id = params[:source_id]

    @job_postings = JobPosting.recent.includes(source: :origin)
    @job_postings = @job_postings.where.not(status: %w[ignored purged]) if params[:status].blank?

    @job_postings = @job_postings.where(company_name: @company) if @company.present?
    @job_postings = @job_postings.where(source_id: @source_id) if @source_id.present?
    @job_postings = @job_postings.search(@query) if @query.present?

    @job_postings = @job_postings.page(params[:page]).per(20)
  end

  def show
    @job_posting = JobPosting.includes(:contacts).find(params[:id])
    ahoy.track 'Viewed Job Posting', job_posting_id: @job_posting.id, title: @job_posting.title
  end
end
