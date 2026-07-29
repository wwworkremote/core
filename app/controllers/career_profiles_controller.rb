# frozen_string_literal: true

class CareerProfilesController < ApplicationController
  before_action :set_career_profile

  def show; end

  def edit; end

  def update
    return sync_from_yaml if params[:sync]
    return enqueue_embedding_only if params[:embed]

    save_career_profile
  end

  def sync_github
    result = LLM::GithubProcessor.call(@career_profile)
    apply_sync_github_result(result)
    redirect_to career_profile_path
  end

  private

  def set_career_profile
    @career_profile = current_user.career_profile || current_user.create_career_profile!
  end

  def sync_from_yaml
    Resume::YamlImporter.call(current_user)
    Resume::EmbeddingJob.perform_later(@career_profile.id)
    redirect_to career_profile_path, notice: "Career profile synchronization initiated."
  end

  def enqueue_embedding_only
    Resume::EmbeddingJob.perform_later(@career_profile.id)
    redirect_to career_profile_path, notice: "Neural vector synthesis initiated."
  end

  def save_career_profile
    return render(:edit, status: :unprocessable_content) unless @career_profile.update(career_profile_params)

    Resume::EmbeddingJob.perform_later(@career_profile.id)
    redirect_to career_profile_path, notice: "Career profile updated and synthesis initiated."
  end

  def apply_sync_github_result(result)
    if result[:success]
      flash[:notice] = "🚀 GitHub technical evidence synchronized successfully."
    else
      flash[:alert] = "Failed to sync GitHub: #{result[:error]}"
    end
  end

  def career_profile_params
    params.expect(career_profile: career_profile_permitted_fields)
  end

  def career_profile_permitted_fields
    [:resume_text, :goals, :skills, :experience_level, :github_url, job_experiences_attributes_param]
  end

  def job_experiences_attributes_param
    { job_experiences_attributes: %i[id title company start_date end_date current description _destroy] }
  end
end
