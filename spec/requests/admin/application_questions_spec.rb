# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ApplicationQuestions" do
  let(:job_posting) { create(:job_posting) }
  let(:user) {
    User.find_or_create_by!(email: "mike@just3ws.com") { |u|
      u.name = "Mike"; u.password = "password"
    }
  }
  let!(:profile) { create(:career_profile, user: user) }

  describe "POST /admin/job_postings/:job_posting_id/application_questions" do
    it "answers instantly via the canned path and redirects with a notice naming the source" do
      create(:work_experience, career_profile: profile, start_date: 5.years.ago.to_date, end_date: nil)

      post admin_job_posting_application_questions_path(job_posting),
           params: { question_text: "How many years of experience do you have?" }

      question = job_posting.application_questions.last
      expect(question.answer_source).to eq("canned")
      expect(question.answer_text).to be_present
      expect(response).to redirect_to(job_posting)
      expect(flash[:notice]).to eq("Answer generated (canned).")
    end

    it "generates an AI answer and redirects with a notice naming the source" do
      create(:work_experience, career_profile: profile, title: "Dev", summary: "A", impact: "B")
      allow(LLM::Orchestrator).to receive(:call).and_return(success: true, output: "Because I love the mission.")

      post admin_job_posting_application_questions_path(job_posting),
           params: { question_text: "Why do you want to work here?" }

      question = job_posting.application_questions.last
      expect(question.answer_source).to eq("ai")
      expect(question.answer_text).to eq("Because I love the mission.")
      expect(flash[:notice]).to eq("Answer generated (ai).")
    end

    it "keeps the question saved and surfaces the guard error when the profile is incomplete" do
      post admin_job_posting_application_questions_path(job_posting),
           params: { question_text: "Why do you want to work here?" }

      question = job_posting.application_questions.last
      expect(question).to be_persisted
      expect(question.answer_text).to be_nil
      expect(flash[:alert]).to include("Profile incomplete")
    end
  end

  describe "DELETE /admin/job_postings/:job_posting_id/application_questions/:id" do
    it "removes the question and redirects to the job posting" do
      question = create(:application_question, user: user, job_posting: job_posting)

      expect {
        delete admin_job_posting_application_question_path(job_posting, question)
      }.to change(ApplicationQuestion, :count).by(-1)

      expect(response).to redirect_to(job_posting)
      expect(flash[:notice]).to eq("Question removed.")
    end
  end
end
