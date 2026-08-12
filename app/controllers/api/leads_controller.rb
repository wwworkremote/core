# frozen_string_literal: true

class Api::LeadsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    render json: Lead.order(id: :desc).page(params[:page]).without_count
  end

  def show
    render json: Lead.find(params.expect(:id))
  end

  # POST /api/leads
  # Fired automatically the moment the extension confirms a job-detail page
  # -- before the user has even opened the review panel. Idempotent on the
  # URL signature so revisiting the same page just refreshes found_at.
  def create
    lead = Lead.find_or_initialize_by(signature: Lead.incoming_signature(params[:url]))
    lead.assign_attributes(lead_params)
    lead.found_at ||= Time.current
    respond_with_save(lead)
  end

  # POST /api/leads/:id/promote
  # Fired when the user submits the review panel (post company selection).
  def promote
    lead = Lead.find(params.expect(:id))
    result = Leads::CaptureService.call(lead: lead, params: promote_params, user: current_user)
    respond_to_promote(lead, result)
  end

  private

  def respond_to_promote(lead, result)
    if result[:success]
      render json: { success: true, lead_id: lead.id, job_posting_id: result[:job_posting].id }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_content
    end
  end

  def respond_with_save(lead)
    if lead.save
      render json: { success: true, id: lead.id, status: lead.status }, status: :created
    else
      render json: { success: false, errors: lead.errors.full_messages }, status: :unprocessable_content
    end
  end

  def lead_params
    params.permit(:url, :provider, :title, :company_name, :location, :raw_html, discovery: {})
  end

  def promote_params
    params.permit(:title, :location, :target_url, :body, :company_id, company: [:name], data: {})
  end
end
