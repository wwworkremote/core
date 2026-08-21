# frozen_string_literal: true

class UserJobPostingsController < ApplicationController
  before_action :set_job_posting, only: %i[create analyze_match generate_artifacts]

  def index
    @user_job_postings = current_user.user_job_postings.includes(:job_posting).order(created_at: :desc)
    @favorites = @user_job_postings.where(status: "favorited")
    @applied = @user_job_postings.where(status: "applied")
  end

  def create
    build_user_job_posting
    @user_job_posting.record_status_event!(params[:status]) if params[:status].present?

    redirect_back_or_to(job_posting_path(@job_posting), notice: "Job status updated.")
  end

  def update
    @user_job_posting = current_user.user_job_postings.find(params.expect(:id))
    return unless @user_job_posting.update(user_job_posting_params)

    redirect_back_or_to(user_job_postings_path, notice: "Job record updated.")
  end

  def destroy
    @user_job_posting = current_user.user_job_postings.find(params.expect(:id))
    @user_job_posting.destroy
    redirect_back_or_to(user_job_postings_path, notice: "Job removed from your list.")
  end

  def analyze_match
    result = LLM::ProfileMatcher.call(current_user, @job_posting, force: forced?)
    flash_llm_result(result, success: "AI alignment scan complete.", failure: "Scan failed")
    redirect_back_or_to(job_posting_path(@job_posting))
  end

  def generate_artifacts
    result = LLM::ArtifactGenerator.call(current_user, @job_posting, force: forced?)
    flash_llm_result(result, success: "Bespoke application artifacts generated and appended to notes.",
                             failure: "Generation failed")
    redirect_back_or_to(job_posting_path(@job_posting))
  end

  private

  def set_job_posting
    @job_posting = JobPosting.find(params.expect(:job_posting_id))
  end

  def build_user_job_posting
    @user_job_posting = current_user.user_job_postings.find_or_initialize_by(job_posting: @job_posting)
    assign_job_search_id
    @user_job_posting.save!
  end

  def assign_job_search_id
    @user_job_posting.job_search_id = params[:job_search_id] if params[:job_search_id].present?
  end

  def forced?
    params[:force] == "true"
  end

  def flash_llm_result(result, success:, failure:)
    if result[:success]
      flash[:notice] = success
    else
      flash[:alert] = "#{failure}: #{result[:error]}"
    end
  end

  # Deliberately excludes :status -- writing that column directly would skip
  # the AASM guards entirely. Status changes go through record_status_event!.
  def user_job_posting_params
    params.expect(user_job_posting: %i[notes])
  end
end
