# frozen_string_literal: true

class Admin::InterviewSessionsController < ApplicationController
  def create
    @job_posting = JobPosting.find(params.expect(:job_posting_id))
    build_session
    @session.save ? redirect_on_session_saved : redirect_on_session_failed
  end

  private

  def build_session
    @session = @job_posting.interview_sessions.build(session_params)
    @session.user = current_user
  end

  def redirect_on_session_saved
    redirect_to @job_posting, notice: "🚀 Interview session initialized in the Laboratory."
  end

  def redirect_on_session_failed
    redirect_to @job_posting, alert: "Failed to initialize session: #{@session.errors.full_messages.join(', ')}"
  end

  def session_params
    params.permit(:session_type, :scheduled_at, :notes, :vibe, :feedback)
  end
end
