# frozen_string_literal: true

class JobPostingsController < ApplicationController
  def index
    @query = params[:q]
    @job_postings = JobPosting.order(published_at: :desc)
    
    if @query.present?
      @job_postings = @job_postings.where('title ILIKE :q OR company ILIKE :q OR body ILIKE :q', q: "%#{@query}%")
    end

    @job_postings = @job_postings.page(params[:page]).per(20)
  end

  def show
    @job_posting = JobPosting.find(params[:id])
  end
end
