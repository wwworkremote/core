# frozen_string_literal: true

class Api::V0::ApplicationQuestionsController < ApiController
  def index
    render json: job_posting.application_questions
  end

  # Mirrors Admin::ApplicationQuestionsController#create -- same
  # find-or-create + AnswerGenerator flow, JSON-shaped for the extension.
  def create
    question = build_question
    return render_errors(question) unless question.persisted?

    render_answer(question)
  end

  private

  def build_question
    job_posting.application_questions.create(question_text: params[:question_text], user: User.first)
  end

  def render_answer(question)
    result = LLM::AnswerGenerator.call(question)
    render json: { success: result[:success], error: result[:error], question: question.reload }
  end

  def job_posting
    @job_posting ||= JobPosting.find(params.expect(:job_posting_id))
  end

  def render_errors(question)
    render json: { success: false, errors: question.errors.full_messages }, status: :unprocessable_content
  end
end
