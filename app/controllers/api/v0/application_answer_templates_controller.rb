# frozen_string_literal: true

class Api::V0::ApplicationAnswerTemplatesController < ApiController
  def index
    render json: current_api_user.application_answer_templates.where(enabled: true).order(updated_at: :desc)
  end

  def create
    attrs = params.expect(application_answer_template: %i[persona_id question_kind normalized_prompt prompt answer
                                                          source enabled])
    template = current_api_user.application_answer_templates.create(attrs)
    template.persisted? ? render(json: { success: true, template: template }) : render_errors(template)
  end

  def update
    template = current_api_user.application_answer_templates.find(params.expect(:id))
    template.update(params.expect(application_answer_template: %i[persona_id question_kind normalized_prompt prompt
                                                                  answer source enabled]))
    template.errors.empty? ? render(json: { success: true, template: template }) : render_errors(template)
  end

  private

  def current_api_user
    @current_api_user ||= User.first
  end

  def render_errors(template)
    render json: { success: false, errors: template.errors.full_messages }, status: :unprocessable_content
  end
end
