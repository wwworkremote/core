# frozen_string_literal: true

class JobSearchesController < ApplicationController
  def index
    @job_searches = current_user.job_searches.order(created_at: :desc)
  end

  def show
    @job_search = current_user.job_searches.find(params.expect(:id))
    @matches = @job_search.matches(limit: 20)
    @skill_matches = @job_search.skill_matches(limit: 10)
  end

  def new
    @job_search = current_user.job_searches.new
    @resumes = current_user.resumes.order(name: :asc, version: :desc)
  end

  def edit
    @job_search = current_user.job_searches.find(params.expect(:id))
    @resumes = current_user.resumes.order(name: :asc, version: :desc)
  end

  def create
    @job_search = current_user.job_searches.new(job_search_params)
    if @job_search.save
      redirect_to job_searches_path, notice: "Job search campaign created."
    else
      @resumes = current_user.resumes.order(name: :asc, version: :desc)
      render :new, status: :unprocessable_content
    end
  end

  def update
    @job_search = current_user.job_searches.find(params.expect(:id))
    if @job_search.update(job_search_params)
      redirect_to job_search_path(@job_search), notice: "Job search campaign updated."
    else
      @resumes = current_user.resumes.order(name: :asc, version: :desc)
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @job_search = current_user.job_searches.find(params.expect(:id))
    @job_search.destroy
    redirect_to job_searches_path, notice: "Job search campaign deleted."
  end

  private

  def job_search_params
    params.expect(job_search: %i[name resume_id status])
  end
end
