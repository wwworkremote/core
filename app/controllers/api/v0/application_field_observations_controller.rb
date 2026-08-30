# frozen_string_literal: true

class Api::V0::ApplicationFieldObservationsController < ApiController
  def create
    observations = Array(params[:observations]).filter_map { |raw| upsert_observation(raw) }
    render json: { success: observations.all?(&:persisted?), observations: observations,
                   question_summary: summary }, status: :ok
  end

  private

  def upsert_observation(raw)
    attrs = to_hash(raw)
    scope = tracked_record.application_field_observations
    scope.find_or_initialize_by(field_key: attrs["field_key"]).tap { |o| o.update(observation_attrs(attrs)) }
  end

  def to_hash(raw)
    raw.respond_to?(:permit) ? raw.permit!.to_h : raw.to_h
  end

  def observation_attrs(attrs)
    classified_attrs(attrs).merge(persona_id: tracked_record.resume_persona_id, context: attrs["context"] || {},
                                  observed_at: Time.current, guided_session_token: params[:guided_session_token])
  end

  def classified_attrs(attrs)
    kind = ApplicationFieldQuestionClassifier.call(attrs["field_label"], type: attrs["field_type"])
    attrs.slice("field_key", "field_label", "field_type", "page_step", "page_url").symbolize_keys
         .merge(question_kind: kind[:question_kind], normalized_prompt: kind[:normalized_prompt])
  end

  def summary
    tracked_record.application_field_observations.group(:question_kind).count
  end

  def tracked_record
    current_api_user.user_job_postings.find_or_create_by!(job_posting: job_posting)
  end

  def current_api_user
    @current_api_user ||= User.first
  end

  def job_posting
    @job_posting ||= JobPosting.find(params.expect(:job_posting_id))
  end
end
