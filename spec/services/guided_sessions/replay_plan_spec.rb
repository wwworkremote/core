# frozen_string_literal: true

require "rails_helper"

RSpec.describe GuidedSessions::ReplayPlan do
  let(:session) { GuidedSession.create!(source_url: "https://jobs.example.com/x", purpose: "application_execution") }

  def event(**attrs)
    session.guided_session_events.create!({ kind: "page_arrived", action: "a", intent: "i", requirement: "recommended",
                                            reversibility: "reversible", approval_state: "not_required",
                                            phase: "resolution", occurred_at: Time.current }.merge(attrs))
  end

  it "marks deterministic reversible steps as auto-advanceable and gates the rest" do
    event(kind: "page_arrived")
    event(kind: "application_page_arrived")
    event(kind: "submission_attempted", reversibility: "irreversible", approval_state: "pending",
          phase: "reorientation")

    plan = described_class.call(session)

    expect(plan[:replayable]).to eq(2)
    expect(plan[:gates]).to eq(1)
    expect(plan[:steps].last).to have_attributes(disposition: :pause)
  end

  it "gates a denied approval" do
    event(reversibility: "irreversible", approval_state: "denied", phase: "reorientation")

    expect(described_class.call(session)[:gates]).to eq(1)
  end
end
