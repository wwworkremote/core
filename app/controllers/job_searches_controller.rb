# frozen_string_literal: true

class JobSearchesController < ApplicationController
  before_action :set_job_search, only: %i[show edit update destroy]

  def index
    @job_searches = current_user.job_searches.order(created_at: :desc)
  end

  def show
    @matches = @job_search.matches(limit: 20)
    @skill_matches = @job_search.skill_matches(limit: 10)
  end

  def new
    @job_search = current_user.job_searches.new
    @resumes = available_resumes
  end

  def edit
    @resumes = available_resumes
  end

  def create
    @job_search = current_user.job_searches.new(job_search_params)
    respond_with_job_search(@job_search.save, job_searches_path, "Job search campaign created.", :new)
  end

  def update
    notice = "Job search campaign updated."
    respond_with_job_search(@job_search.update(job_search_params), job_search_path(@job_search), notice, :edit)
  end

  def destroy
    @job_search.destroy
    redirect_to job_searches_path, notice: "Job search campaign deleted."
  end

  private

  def set_job_search
    @job_search = current_user.job_searches.find(params.expect(:id))
  end

  def available_resumes
    current_user.resumes.order(name: :asc, version: :desc)
  end

  def respond_with_job_search(saved, success_path, notice, fallback_view)
    return redirect_to success_path, notice: notice if saved

    render_failure(fallback_view)
  end

  def render_failure(fallback_view)
    @resumes = available_resumes
    render fallback_view, status: :unprocessable_content
  end

  def job_search_params
    params.expect(job_search: %i[name resume_id status])
  end
end
