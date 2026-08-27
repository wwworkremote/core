# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GuidedSessions" do
  describe "GET /guided_sessions/new" do
    it "renders the copied posting URL intake" do
      get new_guided_session_path

      expect(response).to be_successful
      expect(response.body).to include("Start a guided application session")
      expect(response.body).to include("Job posting URL")
    end
  end

  describe "POST /guided_sessions" do
    it "starts an intake session for a copied posting URL" do
      expect {
        post guided_sessions_path, params: {
          guided_session: { source_url: "https://jobs.example.com/roles/42" }
        }
      }.to change(GuidedSession, :count).by(1)

      session = GuidedSession.order(:id).last
      expect(session.source_url).to eq("https://jobs.example.com/roles/42")
      expect(session.provider).to eq("jobs.example.com")
      expect(session.phase).to eq("intake")
      expect(session.status).to eq("active")
      expect(response).to redirect_to(guided_session_path(session))
    end

    it "rejects a non-http posting URL" do
      expect {
        post guided_sessions_path, params: {
          guided_session: { source_url: "javascript:alert(1)" }
        }
      }.not_to change(GuidedSession, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /guided_sessions/:id" do
    it "shows the current pump-track phase and next move" do
      session = GuidedSession.create!(source_url: "https://jobs.example.com/roles/42")

      get guided_session_path(session)

      expect(response).to be_successful
      expect(response.body).to include("Intake")
      expect(response.body).to include("Review the posting")
    end
  end
end
