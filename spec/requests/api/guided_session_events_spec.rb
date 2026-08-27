# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Guided session events API" do
  let!(:guided_session) { GuidedSession.create!(source_url: "https://jobs.example.com/roles/42") }
  let(:event_params) do
    { event: {
      kind: "posting_reviewed", action: "review posting",
      intent: "Decide whether this opportunity is worth pursuing",
      requirement: "recommended", reversibility: "reversible", approval_state: "not_required",
      page_url: "https://jobs.example.com/roles/42", evidence: { title: "Staff Engineer" }
    } }
  end

  describe "POST /api/guided_sessions/:session_token/events" do
    it "records an annotated transition in the session timeline" do
      expect {
        post api_guided_session_events_path(guided_session.session_token), params: event_params
      }.to change(GuidedSessionEvent, :count).by(1)

      event = guided_session.guided_session_events.order(:id).last
      expect(event.phase).to eq("intake")
      expect(event.intent).to include("worth pursuing")
      expect(event.evidence).to eq("title" => "Staff Engineer")
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("phase" => "intake", "kind" => "posting_reviewed")
    end

    it "rejects an event without intent or a valid classification" do
      post api_guided_session_events_path(guided_session.session_token), params: {
        event: { kind: "posting_reviewed", action: "review posting", reversibility: "unknown" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include("Intent can't be blank")
    end

    it "is unavailable outside the local environment" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("production"))

      post api_guided_session_events_path(guided_session.session_token), params: {
        event: { kind: "posting_reviewed", action: "review posting", intent: "Review" }
      }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /guided_sessions/:id" do
    it "shows recorded events with their intent and approval state" do
      guided_session.guided_session_events.create!(
        kind: "posting_reviewed", action: "review posting", intent: "Understand the opportunity",
        requirement: "required", reversibility: "reversible", approval_state: "not_required",
        phase: "intake", occurred_at: Time.current
      )

      get guided_session_path(guided_session)

      expect(response).to be_successful
      expect(response.body).to include("Understand the opportunity")
      expect(response.body).to include("Required")
    end
  end
end
