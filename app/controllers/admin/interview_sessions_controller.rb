# frozen_string_literal: true

module Admin
  class InterviewSessionsController < ApplicationController
    def create
      @job_posting = JobPosting.find(params[:job_posting_id])
      @session = @job_posting.interview_sessions.build(session_params)
      @session.user = current_user

      if @session.save
        redirect_to @job_posting, notice: '🚀 Interview session initialized in the Laboratory.'
      else
        redirect_to @job_posting, alert: "Failed to initialize session: #{@session.errors.full_messages.join(', ')}"
      end
    end

    private

    def session_params
      params.permit(:session_type, :scheduled_at, :notes, :vibe, :feedback)
    end
  end
end
