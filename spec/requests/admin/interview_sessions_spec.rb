# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::InterviewSessions" do
  let(:job_posting) { create(:job_posting) }

  describe "POST /admin/job_postings/:job_posting_id/interview_sessions" do
    it "creates the session for the current user and redirects with a notice" do
      post admin_job_posting_interview_sessions_path(job_posting),
           params: { session_type: "Technical", scheduled_at: 1.day.from_now }

      session = job_posting.interview_sessions.last
      expect(session).to be_present
      expect(session.user.email).to eq("mike@just3ws.com")
      expect(response).to redirect_to(job_posting)
      expect(flash[:notice]).to eq("🚀 Interview session initialized in the Laboratory.")
    end

    it "redirects with an alert listing validation errors when required fields are missing" do
      post admin_job_posting_interview_sessions_path(job_posting), params: { session_type: "" }

      expect(job_posting.interview_sessions.count).to eq(0)
      expect(response).to redirect_to(job_posting)
      expect(flash[:alert]).to include("Failed to initialize session:")
    end
  end
end
