# frozen_string_literal: true

class CareerProfilesController < ApplicationController
  before_action :set_career_profile

  def show; end

  def edit; end

  def update
    if params[:sync]
      Resume::YamlImporter.call(current_user)
      Resume::ProfileEmbedder.new(@career_profile).call
      redirect_to career_profile_path, notice: 'Career profile synchronized and embedded successfully.'
    elsif params[:embed]
      Resume::ProfileEmbedder.new(@career_profile).call
      redirect_to career_profile_path, notice: 'Neural vectors synchronized successfully.'
    elsif @career_profile.update(career_profile_params)
      Resume::ProfileEmbedder.new(@career_profile).call
      redirect_to career_profile_path, notice: 'Career profile updated and embedded successfully.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def sync_github
    result = LLM::GithubProcessor.call(@career_profile)
    if result[:success]
      flash[:notice] = '🚀 GitHub technical evidence synchronized successfully.'
    else
      flash[:alert] = "Failed to sync GitHub: #{result[:error]}"
    end
    redirect_to career_profile_path
  end

  private

  def set_career_profile
    @career_profile = current_user.career_profile || current_user.create_career_profile!
  end

  def career_profile_params
    params.expect(
      career_profile: [:resume_text, :goals, :skills, :experience_level, :github_url,
                       { job_experiences_attributes: %i[id title company start_date end_date current description _destroy] }]
    )
  end
end
