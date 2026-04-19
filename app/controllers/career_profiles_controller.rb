# frozen_string_literal: true

class CareerProfilesController < ApplicationController
  before_action :set_career_profile

  def show
  end

  def edit
  end

  def update
    if @career_profile.update(career_profile_params)
      redirect_to career_profile_path, notice: "Career profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_career_profile
    @career_profile = current_user.career_profile || current_user.create_career_profile!
  end

  def career_profile_params
    params.require(:career_profile).permit(
      :resume_text, :goals, :skills, :experience_level,
      job_experiences_attributes: [:id, :title, :company, :start_date, :end_date, :current, :description, :_destroy]
    )
  end
end
