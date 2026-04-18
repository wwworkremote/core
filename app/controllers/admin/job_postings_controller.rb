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

    def destroy
      @job_posting = JobPosting.find(params[:id])
      @job_posting.destroy
      redirect_to admin_job_postings_path, notice: "Job posting was successfully deleted."
    end
  end
end
