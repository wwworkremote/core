# frozen_string_literal: true

module Admin
  class JobPostingsController < Admin::ApplicationController
    def index
      @job_postings = JobPosting.recent.includes(source: :origin).page(params[:page]).per(30)
    end

    def show
      @job_posting = JobPosting.find(params[:id])
      return unless params[:frame] == 'semantic_matches'
      @similar_jobs = @job_posting.embedding.present? ? @job_posting.nearest_neighbors(:embedding, distance: 'cosine').limit(5) : []
      render partial: 'semantic_matches', locals: { similar_jobs: @similar_jobs }
    end

    def update
      @job_posting = JobPosting.find(params[:id])

      if params[:action_type] == 'enrich'
        Scraper::Enricher.call(@job_posting)
        flash[:notice] = 'Enrichment complete.'
      elsif params[:action_type] == 'synthesize'
        JobBoards::Categorizer.new.call(@job_posting.id)
        flash[:notice] = 'Synthesis triggered.'
      end

      redirect_back_or_to(admin_job_posting_path(@job_posting))
    end
  end
end
