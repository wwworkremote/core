# frozen_string_literal: true

# Records explicit semantic associations learned from the reverse application
# picker: a visible ATS field mapped to a profile, persona, question, or
# intentional manual source.
class Api::V0::ApplicationFieldMappingsController < ApiController
  def index
    render json: tracked_record.application_field_mappings.order(mapped_at: :desc)
  end

  def create
    mapping = tracked_record.application_field_mappings.new(mapping_attrs)
    mapping.application_field_answer = answer_for(mapping)

    mapping.save ? render(json: { success: true, mapping: mapping }) : render_errors(mapping)
  end

  private

  def tracked_record
    record = current_api_user.user_job_postings.find_or_create_by!(job_posting: job_posting)
    record.update!(application_trace_id: params[:trace_id]) if stale_trace_id?(record)
    record
  end

  def stale_trace_id?(record)
    params[:trace_id].present? && record.application_trace_id != params[:trace_id]
  end

  def mapping_attrs
    mapping_params.merge(mapped_at: Time.current, trace_id: params[:trace_id],
                         guided_session_token: params[:guided_session_token])
  end

  def mapping_params
    params.expect(application_field_mapping: %i[
                    field_key field_label semantic_key semantic_label source_kind provider
                    page_step page_url page_title element_fingerprint element_descriptor context
                  ])
  end

  def answer_for(mapping)
    tracked_record.application_field_answers.find_by(field_key: mapping[:field_key])
  end

  def render_errors(mapping)
    render json: { success: false, errors: mapping.errors.full_messages }, status: :unprocessable_content
  end

  def current_api_user
    @current_api_user ||= User.first
  end

  def job_posting
    @job_posting ||= JobPosting.find(params.expect(:job_posting_id))
  end
end
