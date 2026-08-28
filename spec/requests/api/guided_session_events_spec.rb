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
  let(:application_structure) do
    {
      field_count: 2,
      question_count: 1,
      fields: [
        { field_key: "email", label: "Email", type: "email", classification: "identity", required: true },
        { field_key: "question_1", label: "Why this role?", type: "textarea",
          classification: "screening_question", required: false }
      ]
    }
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

    it "records an application transition in its declared pump-track phase" do
      post api_guided_session_events_path(guided_session.session_token), params: {
        event: event_params.fetch(:event).merge(
          kind: "application_page_arrived",
          action: "Observe application form",
          intent: "Understand the application questions before drafting a response",
          phase: "resolution",
          evidence: application_structure
        )
      }, as: :json

      expect(response).to have_http_status(:created)
      expect(guided_session.reload.phase).to eq("resolution")
      event = guided_session.guided_session_events.last
      expect(event.phase).to eq("resolution")
      expect(event.evidence.fetch("fields").second).to include("label" => "Why this role?", "required" => false)
    end

    it "requires an approval state for irreversible transitions" do
      post api_guided_session_events_path(guided_session.session_token), params: {
        event: event_params.fetch(:event).merge(reversibility: "irreversible", approval_state: "not_required")
      }

      expect(response).to have_http_status(:unprocessable_content)
      errors = response.parsed_body.fetch("errors")
      expect(errors).to include("Approval state must be pending, approved, or denied for irreversible transitions")
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

    it "shows value-free application structure evidence" do
      guided_session.guided_session_events.create!(
        kind: "application_page_arrived", action: "Observe application form",
        intent: "Map the provider flow", requirement: "required", reversibility: "reversible",
        approval_state: "not_required", phase: "resolution", occurred_at: Time.current,
        evidence: { fields: [{ label: "Why this role?", type: "textarea",
                               classification: "screening_question", required: false }] }
      )

      get guided_session_path(guided_session)

      expect(response.body).to include("Observed form structure")
      expect(response.body).to include("Why this role?")
      expect(response.body).to include("Screening question")
    end

    it "offers an explicit decision for a pending irreversible event" do
      event = guided_session.guided_session_events.create!(
        kind: "submission_attempted", action: "Submit application", intent: "Send the reviewed application",
        requirement: "required", reversibility: "irreversible", approval_state: "pending",
        phase: "reorientation", occurred_at: Time.current
      )

      get guided_session_path(guided_session)

      expect(response.body).to include("Approval required")
      expect(response.body).to include("Approve")
      expect(response.body).to include("Deny")
      expect(response.body).to include(approval_guided_session_path(guided_session, event_id: event.id))
    end

    it "records the actor's approval decision" do
      event = guided_session.guided_session_events.create!(
        kind: "submission_attempted", action: "Submit application", intent: "Send the reviewed application",
        requirement: "required", reversibility: "irreversible", approval_state: "pending",
        phase: "reorientation", occurred_at: Time.current
      )

      patch approval_guided_session_path(guided_session, event_id: event.id), params: { approval_state: "denied" }

      expect(response).to redirect_to(guided_session_path(guided_session))
      expect(event.reload.approval_state).to eq("denied")
    end
  end
end
