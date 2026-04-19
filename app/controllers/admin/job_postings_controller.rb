# frozen_string_literal: true

module Admin
  class JobPostingsController < Admin::ApplicationController
    def index
      @job_postings = JobPosting.recent.includes(source: :origin).page(params[:page]).per(30)
    end

    def show
      @job_posting = JobPosting.find(params[:id])
      if params[:frame] == "semantic_matches"
        @similar_jobs = @job_posting.embedding.present? ? @job_posting.nearest_neighbors(:embedding, distance: 'cosine').limit(5) : []
        render partial: "semantic_matches", locals: { similar_jobs: @similar_jobs }
      end
    end

    def update
      if params[:action] == 'enrich'
        @job_posting = JobPosting.find(params[:id])
        Scraper::Enricher.call(@job_posting)
        redirect_to admin_job_posting_path(@job_posting), notice: "Enrichment complete."
      end
    end
  end
end
