# frozen_string_literal: true

class Admin::JobPostingsController < Admin::ApplicationController
  def index
    @status = params[:status]
    @job_postings = JobPosting.recent.includes(source: :origin)

    @job_postings = if @status == "purged"
                      @job_postings.where(status: "purged")
                    else
                      @job_postings.where.not(status: "purged")
                    end

    @job_postings = @job_postings.page(params[:page]).per(50)
  end

  def show
    @job_posting = JobPosting.find(params[:id])
    return unless params[:frame] == "semantic_matches"
    @similar_jobs = if @job_posting.embedding.present?
                      @job_posting.nearest_neighbors(:embedding,
                                                     distance: "cosine").limit(5)
                    else
                      []
                    end
    render partial: "semantic_matches", locals: { similar_jobs: @similar_jobs }
  end

  def update
    @job_posting = JobPosting.find(params[:id])

    if params[:action_type] == "enrich"
      Scraper::Enricher.call(@job_posting)
      flash[:notice] = "Enrichment complete."
    elsif params[:action_type] == "synthesize"
      JobBoards::Categorizer.new.call(@job_posting.id)
      flash[:notice] = "Synthesis triggered."
    end

    redirect_back_or_to(admin_job_posting_path(@job_posting))
  end

  def purge
    @job_posting = JobPosting.find(params[:id])
    @job_posting.purge!
    redirect_back_or_to(admin_job_postings_path, notice: "Job record moved to trash and vectors cleared.")
  end

  def restore
    @job_posting = JobPosting.find(params[:id])
    @job_posting.restore!
    redirect_back_or_to(admin_job_postings_path, notice: "Job record restored to registry.")
  end

  def bulk_action
    ids = params[:job_ids]
    action = params[:bulk_operation]

    if ids.present?
      case action
      when "purge"
        JobPosting.where(id: ids).find_each(&:purge!)
        notice = "#{ids.size} records moved to trash."
      when "restore"
        JobPosting.where(id: ids).find_each(&:restore!)
        notice = "#{ids.size} records restored."
      when "delete"
        JobPosting.where(id: ids).destroy_all
        notice = "#{ids.size} records permanently deleted."
      end
    end

    redirect_back_or_to(admin_job_postings_path, notice: notice || "No records selected.")
  end

  def destroy
    @job_posting = JobPosting.find(params[:id])
    @job_posting.destroy
    redirect_to admin_job_postings_path, notice: "Job posting was permanently deleted."
  end
end
