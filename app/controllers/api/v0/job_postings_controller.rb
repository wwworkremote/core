# frozen_string_literal: true

module Api
  module V0
    class JobPostingsController < ApiController
      def index
        page = params.fetch('page') { 1 }

        render json: JobPosting.order(id: :desc).page(page).without_count
      end

      def show
        id = params[:id]

        render json: JobPosting.find(id)
      end

      # POST /api/v0/job_postings
      # For generic ingestion from any board.
      def create
        # Use signature if provided, or generate from URL
        signature = params[:signature] || Digest::SHA256.hexdigest(params[:url])
        
        job = JobPosting.find_or_initialize_by(signature: signature)
        job.assign_attributes(job_params)
        
        if job.save
          render json: { success: true, id: job.id, status: job.crawl_status }, status: :created
        else
          render json: { success: false, errors: job.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v0/job_postings/:id/enrich
      # For updating an existing job with rich context.
      def enrich
        job = JobPosting.find(params[:id])
        
        if job.update(enrich_params.merge(crawl_status: 'enriched', enriched_at: Time.current))
          # Optionally trigger re-alignment if body changed significantly
          LLM::ProfileMatcher.call(User.first, job) if params[:realign]
          
          render json: { success: true, id: job.id }
        else
          render json: { success: false, errors: job.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def job_params
        params.permit(:title, :company, :location, :target_url, :body, data: {})
      end

      def enrich_params
        params.permit(:body, data: {})
      end
    end
  end
end
