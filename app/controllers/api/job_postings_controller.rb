# frozen_string_literal: true

class Api::JobPostingsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def enrich
    perform_enrichment
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: "Job posting #{params[:id]} not found." }, status: :not_found
  end

  private

  def perform_enrichment
    return render_missing_description if markdown_body.blank?

    apply_enrichment!
    render json: { success: true, message: "Job ##{job_posting.id} enriched." }
  end

  def job_posting
    @job_posting ||= JobPosting.find(params.expect(:id))
  end

  def markdown_body
    @markdown_body ||= resolver.call
  end

  def resolver
    JobPostingEnrichment::DescriptionResolver.new(
      extracted: extracted, html: params[:html], url: params[:url], provider: params[:provider]
    )
  end

  def extracted
    @extracted ||= params[:extracted]&.to_unsafe_h || {}
  end

  def apply_enrichment!
    attrs = JobPostingEnrichment::AttributeBuilder.new(job_posting, extracted, markdown_body).call
    job_posting.update!(attrs)
    analyze
  end

  def render_missing_description
    render json: { success: false, error: "No description found in captured content." },
           status: :unprocessable_content
  end

  def analyze
    JobBoards::Categorizer.new(job_posting).call
    JobBoards::Embedder.new(job_posting).call
  end
end
