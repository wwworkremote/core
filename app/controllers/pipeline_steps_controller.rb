# frozen_string_literal: true

class PipelineStepsController < ApplicationController
  def create
    @job_posting = JobPosting.find(params[:job_posting_id])
    
    # Handle status transitions or manual notes
    if params[:status].present?
      # Whitelist AASM events to prevent dangerous send
      allowed_events = %w[favorite apply interview offer archive]
      if allowed_events.include?(params[:status])
        @job_posting.send("#{params[:status]}!")
        @job_posting.pipeline_steps.create!(status: params[:status], note: "Status changed to #{params[:status]}")
      end
    elsif params[:note].present?
      @job_posting.add_pipeline_note(params[:note], link: params[:link])
    end

    redirect_to admin_job_posting_path(@job_posting), notice: "Activity logged."
  end
end
