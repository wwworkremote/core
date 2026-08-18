# frozen_string_literal: true

# First-pass winnowing queue: one untriaged JobPosting at a time, decisions
# recorded via Admin::PipelineStepsController#create (see TASK-62 plan).
class JobPostingTriageController < ApplicationController
  def show
    apply_queue_params
    @job_posting = next_candidate
  end

  private

  def apply_queue_params
    session.delete(:triage_skipped_ids) if params[:reset_skips].present?
    skip_current! if params[:skip].present?
  end

  def skip_current!
    session[:triage_skipped_ids] ||= []
    session[:triage_skipped_ids] << params[:skip].to_i
  end

  def next_candidate
    JobPosting.where(status: "none")
              .where.not(id: session[:triage_skipped_ids] || [])
              .recent
              .first
  end
end
