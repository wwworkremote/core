# frozen_string_literal: true

class Admin::PipelineStepsController < Admin::ApplicationController
  def create
    @job_posting = JobPosting.find(params.expect(:job_posting_id))

    # Handle status transitions or manual notes
    if params[:status].present?
      # Whitelist AASM events to prevent dangerous send
      allowed_events = %w[favorite apply interview offer archive]
      if allowed_events.include?(params[:status])
        @job_posting.send("#{params[:status]}!")
        @job_posting.pipeline_steps.create!(
          status: params[:status],
          note: "Status changed to #{params[:status]}",
          user: current_user
        )
      end
    elsif params[:note].present?
      @job_posting.pipeline_steps.create!(
        status: "noted",
        note: params[:note],
        link: params[:link],
        artifacts: params[:artifacts],
        user: current_user
      )
    end

    redirect_to admin_job_posting_path(@job_posting), notice: "Activity logged."
  end
end
