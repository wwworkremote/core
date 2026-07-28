# frozen_string_literal: true

class Admin::InterviewQuestionsController < ApplicationController
  def create
    @session = InterviewSession.find(params.expect(:interview_session_id))
    @question = @session.interview_questions.build(question_params)

    if @question.save
      redirect_to @session.job_posting, notice: "Knowledge node appended to session."
    else
      redirect_to @session.job_posting, alert: "Failed to log query."
    end
  end

  private

  def question_params
    params.permit(:question_text, :answer_text, :category)
  end
end
