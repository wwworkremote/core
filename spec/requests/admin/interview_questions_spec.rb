# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::InterviewQuestions" do
  let(:job_posting) { create(:job_posting) }
  let(:user) {
    User.find_or_create_by!(email: "mike@just3ws.com") { |u|
      u.name = "Mike"; u.password = "password"
    }
  }
  let(:session) {
    InterviewSession.create!(job_posting: job_posting, user: user, session_type: "Technical",
                             scheduled_at: 1.day.from_now)
  }

  describe "POST /admin/interview_sessions/:interview_session_id/interview_questions" do
    it "appends the question and redirects with a notice on success" do
      post admin_interview_session_interview_questions_path(session),
           params: { question_text: "What's your approach to caching?", category: "Technical" }

      expect(session.interview_questions.count).to eq(1)
      expect(response).to redirect_to(job_posting)
      expect(flash[:notice]).to eq("Knowledge node appended to session.")
    end

    it "redirects with an alert when the question fails to save" do
      post admin_interview_session_interview_questions_path(session), params: { question_text: "" }

      expect(session.interview_questions.count).to eq(0)
      expect(response).to redirect_to(job_posting)
      expect(flash[:alert]).to eq("Failed to log query.")
    end
  end
end
