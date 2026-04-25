# frozen_string_literal: true

class UserJobPostingsController < ApplicationController
  def index
    @user_job_postings = current_user.user_job_postings.includes(:job_posting).order(created_at: :desc)
    @favorites = @user_job_postings.where(status: "favorited")
    @applied = @user_job_postings.where(status: "applied")
  end

  def create
    @job_posting = JobPosting.find(params[:job_posting_id])
    @user_job_posting = current_user.user_job_postings.find_or_initialize_by(job_posting: @job_posting)

    if params[:status].present?
      @user_job_posting.status = params[:status]
      @user_job_posting.save!

      # Log to pipeline as well
      current_user.pipeline_steps.create!(
        job_posting: @job_posting,
        status: params[:status],
        note: "User marked as #{params[:status]}"
      )
    end

    redirect_back_or_to(job_posting_path(@job_posting), notice: "Job status updated.")
  end

  def update
    @user_job_posting = current_user.user_job_postings.find(params[:id])
    return unless @user_job_posting.update(user_job_posting_params)
    redirect_back_or_to(user_job_postings_path, notice: "Job record updated.")
  end

  def destroy
    @user_job_posting = current_user.user_job_postings.find(params[:id])
    @user_job_posting.destroy
    redirect_back_or_to(user_job_postings_path, notice: "Job removed from your list.")
  end

  def analyze_match
    @job_posting = JobPosting.find(params[:job_posting_id])

    # We call this synchronously for now to provide immediate feedback,
    # but could be moved to an ActiveJob if it takes too long.
    result = LLM::ProfileMatcher.call(current_user, @job_posting)

    if result[:success]
      flash[:notice] = "AI alignment scan complete."
    else
      flash[:alert] = "Scan failed: #{result[:error]}"
    end

    redirect_back_or_to(job_posting_path(@job_posting))
  end

  def generate_artifacts
    @job_posting = JobPosting.find(params[:job_posting_id])
    result = LLM::ArtifactGenerator.call(current_user, @job_posting)

    if result[:success]
      flash[:notice] = "Bespoke application artifacts generated and appended to notes."
    else
      flash[:alert] = "Generation failed: #{result[:error]}"
    end

    redirect_back_or_to(job_posting_path(@job_posting))
  end

  private

  def user_job_posting_params
    params.expect(user_job_posting: %i[status notes])
  end
end
