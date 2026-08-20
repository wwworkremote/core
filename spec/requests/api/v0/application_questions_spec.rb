# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V0::ApplicationQuestions" do
  let!(:job) { create(:job_posting) }

  describe "GET /api/v0/job_postings/:job_posting_id/application_questions" do
    it "returns the job posting's application questions" do
      question = create(:application_question, job_posting: job, question_text: "Why us?", answer_text: "Because",
                                               answer_source: "canned")

      get api_v0_job_posting_application_questions_path(job), as: :json

      json = response.parsed_body
      expect(json.first).to include("id" => question.id, "question_text" => "Why us?", "answer_text" => "Because",
                                    "answer_source" => "canned")
    end
  end

  describe "POST /api/v0/job_postings/:job_posting_id/application_questions" do
    it "creates the question and generates an answer" do
      user = create(:user)
      allow(User).to receive(:first).and_return(user)
      allow(LLM::AnswerGenerator).to receive(:call) do |question|
        question.update!(answer_text: "Generated answer", answer_source: "ai")
        { success: true, answer: "Generated answer", source: "ai" }
      end

      expect {
        post api_v0_job_posting_application_questions_path(job), params: { question_text: "Why remote?" }, as: :json
      }.to change(ApplicationQuestion, :count).by(1)

      json = response.parsed_body
      expect(json["success"]).to be true
      expect(json["question"]["answer_text"]).to eq("Generated answer")
    end

    it "returns errors when the question fails to save" do
      post api_v0_job_posting_application_questions_path(job), params: { question_text: "" }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["success"]).to be false
    end
  end
end
