# frozen_string_literal: true

class Api::V0::ApplicationFieldObservationsController < ApiController
  def create
    observations = Array(params[:observations]).filter_map do |raw|
      attrs = raw.respond_to?(:permit) ? raw.permit!.to_h : raw.to_h
      kind = ApplicationFieldQuestionClassifier.call(attrs["field_label"], type: attrs["field_type"])
      tracked_record.application_field_observations.find_or_initialize_by(field_key: attrs["field_key"]).tap do |observation|
        observation.assign_attributes(
        field_key: attrs["field_key"], field_label: attrs["field_label"], field_type: attrs["field_type"],
        question_kind: kind[:question_kind], normalized_prompt: kind[:normalized_prompt],
        persona_id: tracked_record.resume_persona_id, page_step: attrs["page_step"],
        page_url: attrs["page_url"], context: attrs["context"] || {}, observed_at: Time.current
        )
        observation.save
      end
    end
    render json: { success: observations.all?(&:persisted?), observations: observations,
                   question_summary: summary }, status: :ok
  end

  private

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
