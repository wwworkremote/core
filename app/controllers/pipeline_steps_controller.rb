# frozen_string_literal: true

class PipelineStepsController < ApplicationController
  def create
    @job_posting = JobPosting.find(params[:job_posting_id])
    
    # Handle status transitions or manual notes
    if params[:status].present?
      @job_posting.send("#{params[:status]}!") if @job_posting.respond_to?("#{params[:status]}!")
      @job_posting.pipeline_steps.create!(status: params[:status], note: "Status changed to #{params[:status]}")
    elsif params[:note].present?
      @job_posting.add_pipeline_note(params[:note], link: params[:link])
    end

    redirect_to admin_job_posting_path(@job_posting), notice: "Activity logged."
  end
end
