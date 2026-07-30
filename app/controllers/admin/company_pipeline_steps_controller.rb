# frozen_string_literal: true

class Admin::CompanyPipelineStepsController < Admin::ApplicationController
  ALLOWED_STATUS_EVENTS = %w[favorite archive].freeze

  def create
    @company = Company.find(params.expect(:company_id))
    log_activity
    redirect_to admin_company_path(@company), notice: "Activity logged."
  end

  private

  def log_activity
    if params[:status].present?
      apply_status_event
    elsif params[:note].present?
      apply_note_event
    end
  end

  def apply_note_event
    @company.add_pipeline_note(params[:note], link: params[:link])
  end

  # Whitelist AASM events to prevent dangerous send
  def apply_status_event
    return unless ALLOWED_STATUS_EVENTS.include?(params[:status])

    @company.send("#{params[:status]}!")
    log_status_change_step
  end

  def log_status_change_step
    @company.company_pipeline_steps.create!(status: params[:status], note: "Status changed to #{params[:status]}")
  end
end
