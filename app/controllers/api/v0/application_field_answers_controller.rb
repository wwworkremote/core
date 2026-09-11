# frozen_string_literal: true

# Records explicit extension fills against the tracked application. The page
# never submits automatically: each row arrives only after the user clicks
# Fill in the side panel.
class Api::V0::ApplicationFieldAnswersController < ApiController
  def index
    render json: tracked_record.application_field_answers.order(provided_at: :desc)
  end

  def create
    answer = upsert_answer
    answer.save ? render_success(answer) : render_errors(answer)
  end

  private

  def upsert_answer
    answer = tracked_record.application_field_answers.find_or_initialize_by(field_key: field_params[:field_key])
    answer.assign_attributes(answer_attrs)
    answer
  end

  def answer_attrs
    field_params.merge(provided_at: Time.current, trace_id: params[:trace_id],
                       guided_session_token: params[:guided_session_token])
  end

  def tracked_record
    record = current_api_user.user_job_postings.find_or_create_by!(job_posting: job_posting)
    record.update!(application_trace_id: params[:trace_id]) if stale_trace_id?(record)
    record
  end

  def stale_trace_id?(record)
    params[:trace_id].present? && record.application_trace_id != params[:trace_id]
  end

  def field_params
    params.expect(application_field_answer: %i[field_key field_label field_type answer answer_source page_url])
  end

  def render_success(answer)
    render json: { success: true, answer: answer }
  end

  def render_errors(answer)
    render json: { success: false, errors: answer.errors.full_messages }, status: :unprocessable_content
  end

  def current_api_user
    @current_api_user ||= User.first
  end

  def job_posting
    @job_posting ||= JobPosting.find(params.expect(:job_posting_id))
  end
end
