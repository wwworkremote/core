# frozen_string_literal: true

class Admin::PipelineStepsController < Admin::ApplicationController
  ALLOWED_STATUS_EVENTS = %w[favorite apply interview offer archive].freeze

  def create
    @job_posting = JobPosting.find(params.expect(:job_posting_id))
    log_activity
    redirect_to admin_job_posting_path(@job_posting), notice: "Activity logged."
  end

  private

  # Handle status transitions or manual notes
  def log_activity
    if params[:status].present?
      apply_status_event
    elsif params[:note].present?
      log_note_step
    end
  end

  # Whitelist AASM events to prevent dangerous send
  def apply_status_event
    return unless ALLOWED_STATUS_EVENTS.include?(params[:status])

    @job_posting.send("#{params[:status]}!")
    log_status_change_step
  end

  def log_status_change_step
    @job_posting.pipeline_steps.create!(
      status: params[:status],
      note: "Status changed to #{params[:status]}",
      user: current_user
    )
  end

  # One cohesive create! call -- splitting it further would obscure it,
  # not simplify it.
  # rubocop:disable Metrics/MethodLength
  def log_note_step
    @job_posting.pipeline_steps.create!(
      status: "noted",
      note: params[:note],
      link: params[:link],
      artifacts: params[:artifacts],
      user: current_user
    )
  end
  # rubocop:enable Metrics/MethodLength
end
