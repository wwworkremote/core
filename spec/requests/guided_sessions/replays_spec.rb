# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GuidedSessions::Replays" do
  let(:session) do
    GuidedSession.create!(source_url: "https://wwworkremote.localhost/sandbox/postings/1",
                          purpose: "application_execution", status: "completed")
  end

  it "starts a replay from the session page" do
    expect { post guided_session_replays_path(session) }.to change(GuidedSessionReplay, :count).by(1)
    expect(response).to redirect_to(guided_session_path(session))
  end

  it "refuses a real-site replay without the opt-in and explains why" do
    real = GuidedSession.create!(source_url: "https://boards.greenhouse.io/acme/jobs/1",
                                 purpose: "application_execution", status: "completed")

    post guided_session_replays_path(real)

    expect(GuidedSessionReplay.count).to eq(0)
    expect(flash[:alert]).to include("real-site")
  end

  it "returns the current instruction as JSON for the extension banner" do
    replay = session.guided_session_replays.create!
    session.guided_session_events.create!(kind: "page_arrived", action: "a", intent: "i", requirement: "recommended",
                                          reversibility: "reversible", approval_state: "not_required",
                                          phase: "resolution", occurred_at: Time.current)

    get guided_session_replay_path(session, replay), as: :json

    expect(response.parsed_body["instruction"]).to be_present
    expect(response.parsed_body["replay"]).to include("status" => "running")
  end

  it "stops a replay" do
    replay = session.guided_session_replays.create!

    patch guided_session_replay_path(session, replay), params: { command: "stop" }

    expect(replay.reload.status).to eq("stopped")
  end
end
