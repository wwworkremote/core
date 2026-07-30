# frozen_string_literal: true

class Api::V0::JobPostingsController < ApiController
  def index
    page = params.fetch("page", 1)

    render json: JobPosting.order(id: :desc).page(page).without_count
  end

  def show
    id = params[:id]

    render json: JobPosting.find(id)
  end

  # POST /api/v0/job_postings
  # For generic ingestion from any board.
  def create
    job = JobPosting.find_or_initialize_by(signature: incoming_signature)
    job.assign_attributes(job_params)

    respond_with_save(job, success_status: :created)
  end

  # POST /api/v0/job_postings/:id/enrich
  # For updating an existing job with rich context.
  def enrich
    job = JobPosting.find(params.expect(:id))
    apply_enrichment(job)
  end

  private

  def apply_enrichment(job)
    updated = job.update(enrich_params.merge(crawl_status: "enriched", enriched_at: Time.current))
    respond_to_enrichment(job, updated)
  end

  def respond_to_enrichment(job, updated)
    return render_errors(job) unless updated

    trigger_realignment(job) if params[:realign]
    render json: { success: true, id: job.id }
  end

  # Use the provided signature if present, or generate one from the URL
  def incoming_signature
    params[:signature] || Digest::SHA256.hexdigest(params[:url])
  end

  def respond_with_save(job, success_status:)
    if job.save
      render json: { success: true, id: job.id, status: job.crawl_status }, status: success_status
    else
      render_errors(job)
    end
  end

  def render_errors(job)
    render json: { success: false, errors: job.errors.full_messages }, status: :unprocessable_content
  end

  # Optionally trigger re-alignment if body changed significantly
  def trigger_realignment(job)
    LLM::ProfileMatcher.call(User.first, job)
  end

  def job_params
    params.permit(:title, :company, :location, :target_url, :body, data: {})
  end

  def enrich_params
    params.permit(:body, data: {})
  end
end
