# frozen_string_literal: true

# Selects and exposes the immutable application context: personal fields plus
# one canonical just3ws resume persona snapshot.
class Api::V0::ApplicationContextsController < ApiController
  def show
    render json: context_payload
  end

  # rubocop:disable-next Metrics/AbcSize, Metrics/MethodLength
  def update
    context = Resume::PersonaContext.call(params.expect(:persona_id))
    record = tracked_record
    record.update!(resume_persona_id: context.fetch("id"),
                   resume_persona_snapshot: context,
                   application_profile_snapshot: ProfileContactFields.call(current_api_user))
    render json: context_payload(record)
  rescue KeyError => e
    render json: { success: false, error: e.message }, status: :unprocessable_content
  end

  private

  def context_payload(record = tracked_record)
    { personas: Resume::PersonaContext.personas, selected_persona_id: record.resume_persona_id,
      persona: record.resume_persona_snapshot, profile: application_profile(record),
      field_answers: record.application_field_answers.order(provided_at: :desc),
      mappings: record.application_field_mappings.order(mapped_at: :desc),
      answer_templates: current_api_user.application_answer_templates.where(enabled: true) }
      .merge(question_summary: record.application_field_observations.group(:question_kind).count)
  end

  def application_profile(record)
    record.application_profile_snapshot.presence || ProfileContactFields.call(current_api_user)
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
