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
    render json: {
      success: true,
      message: "Job ##{job_posting.id} enriched.",
      job_posting_id: job_posting.id,
      lead_id: job_posting.leads.order(id: :desc).pick(:id)
    }
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

  # rubocop:disable-next Metrics/MethodLength
  def extracted
    return {} if params[:extracted].blank?

    raw = params[:extracted]
    ac_params = raw.is_a?(ActionController::Parameters) ? raw : ActionController::Parameters.new(raw)

    ac_params.permit(
      :title, :company, :location, :apply_url, :posted_at, :skills,
      :canonical_url,
      :salary_min, :salary_max, :salary_currency, :salary_unit, :salary,
      :employment_type, :remote, :experience, :valid_through,
      :education, :qualifications, :responsibilities, :benefits,
      :company_logo_url, :industry, :description_text, :description_html,
      skills: []
    ).to_h.tap do |attrs|
      # Workday pages often expose the posting's canonical URL while the
      # review panel leaves Apply URL blank. Do not preserve a stale URL from
      # the previously selected SPA posting in that case.
      attrs["apply_url"] ||= attrs["canonical_url"].presence || params[:url].presence
    end
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
