# frozen_string_literal: true

class Api::V0::ApplicationInsightsController < ApiController
  def index
    observations = current_api_user.user_job_postings.joins(:application_field_observations)
                   .merge(ApplicationFieldObservation.order(:question_kind, :normalized_prompt))
    if params[:job_posting_id].present?
      observations = observations.where(job_posting_id: params[:job_posting_id])
    end

    rows = observations.group(:question_kind, :normalized_prompt).count
    render json: { success: true, total_questions: observations.count,
                   by_kind: observations.group(:question_kind).count,
                   common_questions: rows.sort_by { |_key, count| -count }.first(25).map { |(kind, prompt), count|
                     { question_kind: kind, normalized_prompt: prompt, occurrences: count }
                   } }
  end

  private

  def current_api_user
    @current_api_user ||= User.first
  end
end
