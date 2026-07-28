# frozen_string_literal: true

class Admin::JobPostingsController < Admin::ApplicationController
  ACTION_HANDLERS = {
    "enrich" => ->(job_posting) { Scraper::Enricher.call(job_posting) },
    "synthesize" => ->(job_posting) { JobBoards::Categorizer.new(job_posting).call(force: true) }
  }.freeze

  ACTION_NOTICES = {
    "enrich" => "Enrichment complete.",
    "synthesize" => "Synthesis triggered."
  }.freeze

  BULK_OPERATIONS = {
    "purge" => ->(scope) { scope.find_each(&:purge!) },
    "restore" => ->(scope) { scope.find_each(&:restore!) },
    "delete" => ->(scope) { scope.destroy_all }
  }.freeze

  BULK_NOTICE_TEXT = {
    "purge" => "moved to trash",
    "restore" => "restored",
    "delete" => "permanently deleted"
  }.freeze

  def index
    @status = params[:status]
    @job_postings = filtered_job_postings.page(params[:page]).per(50)
  end

  def show
    @job_posting = JobPosting.find(params.expect(:id))
    return unless params[:frame] == "semantic_matches"

    @similar_jobs = semantic_matches(@job_posting)
    render partial: "semantic_matches", locals: { similar_jobs: @similar_jobs }
  end

  def update
    @job_posting = JobPosting.find(params.expect(:id))
    perform_action(params[:action_type])
    redirect_back_or_to(admin_job_posting_path(@job_posting))
  end

  def purge
    @job_posting = JobPosting.find(params.expect(:id))
    @job_posting.purge!
    redirect_back_or_to(admin_job_postings_path, notice: "Job record moved to trash and vectors cleared.")
  end

  def restore
    @job_posting = JobPosting.find(params.expect(:id))
    @job_posting.restore!
    redirect_back_or_to(admin_job_postings_path, notice: "Job record restored to registry.")
  end

  def bulk_action
    redirect_back_or_to(admin_job_postings_path, notice: bulk_action_notice)
  end

  def destroy
    @job_posting = JobPosting.find(params.expect(:id))
    @job_posting.destroy
    redirect_to admin_job_postings_path, notice: "Job posting was permanently deleted."
  end

  private

  def filtered_job_postings
    scope = JobPosting.recent
    @status == "purged" ? scope.where(status: "purged") : scope.where.not(status: "purged")
  end

  def semantic_matches(job_posting)
    return [] if job_posting.embedding.blank?

    job_posting.nearest_neighbors(:embedding, distance: "cosine").limit(5)
  end

  def perform_action(action_type)
    handler = ACTION_HANDLERS[action_type]
    return unless handler

    handler.call(@job_posting)
    flash[:notice] = ACTION_NOTICES[action_type]
  end

  def bulk_action_notice
    ids = params[:job_ids]
    operation = BULK_OPERATIONS[params[:bulk_operation]]
    return "No records selected." if ids.blank? || operation.nil?

    apply_bulk_operation(operation, ids)
  end

  def apply_bulk_operation(operation, ids)
    operation.call(JobPosting.where(id: ids))
    "#{ids.size} records #{bulk_notice_text}."
  end

  def bulk_notice_text
    BULK_NOTICE_TEXT[params[:bulk_operation]]
  end
end
