# frozen_string_literal: true

class Admin::InterviewQuestionsController < ApplicationController
  def create
    @session = InterviewSession.find(params.expect(:interview_session_id))
    @question = @session.interview_questions.build(question_params)
    @question.save ? redirect_on_question_saved : redirect_on_question_failed
  end

  private

  def redirect_on_question_saved
    redirect_to @session.job_posting, notice: "Knowledge node appended to session."
  end

  def redirect_on_question_failed
    redirect_to @session.job_posting, alert: "Failed to log query."
  end

  def question_params
    params.permit(:question_text, :answer_text, :category)
  end
end
