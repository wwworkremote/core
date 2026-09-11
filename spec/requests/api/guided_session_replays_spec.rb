# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::GuidedSessionReplays" do
  let(:session) do
    GuidedSession.create!(source_url: "https://wwworkremote.localhost/sandbox/postings/1",
                          purpose: "application_execution", status: "completed")
  end

  def event(**attrs)
    session.guided_session_events.create!({ kind: "page_arrived", action: "a", intent: "i", requirement: "recommended",
                                            reversibility: "reversible", approval_state: "not_required",
                                            phase: "resolution", occurred_at: Time.current }.merge(attrs))
  end

  it "reports no active replay by session token" do
    get "/api/guided_sessions/#{session.session_token}/replay"

    expect(response.parsed_body).to eq("active" => false)
  end

  it "returns the current fill instruction for the banner" do
    event
    application = create(:user_job_posting)
    session.update!(user_job_posting: application)
    create(:application_field_answer, user_job_posting: application, field_key: "email", field_label: "Email",
                                      answer: "x@y.z", answer_source: "profile")
    session.guided_session_replays.create!

    get "/api/guided_sessions/#{session.session_token}/replay"

    expect(response.parsed_body.dig("instruction", "action")).to eq("fill")
    expect(response.parsed_body.dig("instruction", "fields", 0, "answer")).to eq("x@y.z")
  end

  it "advances a plain step, then reports the gate ahead" do
    event(kind: "page_arrived")
    event(kind: "submission_attempted", reversibility: "irreversible", approval_state: "pending",
          phase: "reorientation")
    replay = session.guided_session_replays.create!

    patch "/api/guided_sessions/#{session.session_token}/replay", params: { command: "advance" }

    expect(response.parsed_body.dig("instruction", "action")).to eq("gate")
    expect(replay.reload.current_step).to eq(1)
  end

  it "ends the replay when a gate is approved" do
    event(kind: "submission_attempted", reversibility: "irreversible", approval_state: "pending",
          phase: "reorientation")
    replay = session.guided_session_replays.create!
    get "/api/guided_sessions/#{session.session_token}/replay"

    patch "/api/guided_sessions/#{session.session_token}/replay", params: { command: "approve_gate" }

    expect(replay.reload.status).to eq("completed")
    expect(response.parsed_body["active"]).to be(false)
  end
end
