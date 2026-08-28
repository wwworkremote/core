# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GuidedSessions" do
  describe "GET /guided_sessions/new" do
    it "renders the copied posting URL intake" do
      get new_guided_session_path

      expect(response).to be_successful
      expect(response.body).to include("Start a guided application session")
      expect(response.body).to include("Job posting URL")
      expect(response.body).to include("Research the application")
      expect(response.body).to include("Work toward applying")
      document = response.parsed_body
      expect(document.at_css('input[value="application_research"]')["checked"]).to eq("checked")
    end
  end

  describe "POST /guided_sessions" do
    it "starts an intake session for a copied posting URL" do
      expect {
        post guided_sessions_path, params: {
          guided_session: {
            source_url: "https://jobs.example.com/roles/42",
            purpose: "application_research"
          }
        }
      }.to change(GuidedSession, :count).by(1)

      session = GuidedSession.order(:id).last
      expect(session.source_url).to eq("https://jobs.example.com/roles/42")
      expect(session.provider).to eq("jobs.example.com")
      expect(session.phase).to eq("intake")
      expect(session.status).to eq("active")
      expect(session.purpose).to eq("application_research")
      expect(response).to redirect_to(guided_session_path(session))
    end

    it "rejects an unknown session purpose" do
      expect {
        post guided_sessions_path, params: {
          guided_session: { source_url: "https://jobs.example.com/roles/42", purpose: "auto_submit" }
        }
      }.not_to change(GuidedSession, :count)

      expect(response).to have_http_status(:unprocessable_content)
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
      session = GuidedSession.create!(source_url: "https://jobs.example.com/roles/42", purpose: "application_research")

      get guided_session_path(session)

      expect(response).to be_successful
      expect(response.body).to include("Intake")
      expect(response.body).to include("Review the posting")
      expect(response.body).to include("Research mode")
      expect(response.body).to include("Application research")
    end

    it "renders the pump-track playback map and durable resume position" do
      session = GuidedSession.create!(source_url: "https://jobs.example.com/roles/42", playback_position: 2)

      get guided_session_path(session)

      expect(response).to be_successful
      expect(response.body).to include('data-controller="guided-session-playback"')
      expect(response.body).to include("Playback position: 2")
      expect(response.body).to include("Play lap")
    end
  end

  describe "PATCH /guided_sessions/:id/playback" do
    it "persists the playback position for a later handoff" do
      session = GuidedSession.create!(source_url: "https://jobs.example.com/roles/42")

      patch playback_guided_session_path(session), params: { position: 3 }

      expect(response).to have_http_status(:ok)
      expect(session.reload.playback_position).to eq(3)
      expect(response.parsed_body).to include("position" => 3)
    end

    it "rejects a negative playback position" do
      session = GuidedSession.create!(source_url: "https://jobs.example.com/roles/42")

      patch playback_guided_session_path(session), params: { position: -1 }

      expect(response).to have_http_status(:unprocessable_content)
      expect(session.reload.playback_position).to eq(0)
    end
  end
end
