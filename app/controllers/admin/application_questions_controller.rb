# frozen_string_literal: true

class Admin::ApplicationQuestionsController < ApplicationController
  def create
    @job_posting = JobPosting.find(params.expect(:job_posting_id))
    build_question
    return redirect_on_question_failed unless @question.persisted?

    generate_answer
  end

  def destroy
    @question = ApplicationQuestion.find(params.expect(:id))
    @job_posting = @question.job_posting
    @question.destroy
    redirect_to @job_posting, notice: "Question removed."
  end

  private

  def build_question
    @question = @job_posting.application_questions.create(question_text: params[:question_text], user: current_user)
  end

  def generate_answer
    result = LLM::AnswerGenerator.call(@question, force: forced?)
    result[:success] ? redirect_on_answer_generated(result) : redirect_on_answer_failed(result)
  end

  def redirect_on_question_failed
    redirect_to @job_posting, alert: "Failed to save question."
  end

  def redirect_on_answer_generated(result)
    redirect_to @job_posting, notice: "Answer generated (#{result[:source]})."
  end

  def redirect_on_answer_failed(result)
    redirect_to @job_posting, alert: "Question saved, but answer generation failed: #{result[:error]}"
  end

  def forced?
    params[:force] == "true"
  end
end
