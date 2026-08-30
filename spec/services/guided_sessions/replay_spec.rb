# frozen_string_literal: true

require "rails_helper"

RSpec.describe GuidedSessions::Replay do
  def session(**attrs)
    GuidedSession.create!({ source_url: "https://wwworkremote.localhost/sandbox/postings/1",
                            purpose: "application_execution", status: "completed" }.merge(attrs))
  end

  def event(guided, **attrs)
    guided.guided_session_events.create!({ kind: "page_arrived", action: "a", intent: "i", requirement: "recommended",
                                           reversibility: "reversible", approval_state: "not_required",
                                           phase: "resolution", occurred_at: Time.current }.merge(attrs))
  end

  describe ".start" do
    it "refuses a session that has not completed" do
      expect { described_class.start(session(status: "active")) }.to raise_error(described_class::Error, /completed/)
    end

    it "refuses a second concurrent replay" do
      s = session
      described_class.start(s)
      expect { described_class.start(s) }.to raise_error(described_class::Error, /already running/)
    end

    it "refuses a real-site session without an explicit opt-in" do
      real = session(source_url: "https://boards.greenhouse.io/acme/jobs/1")
      expect { described_class.start(real) }.to raise_error(described_class::Error, /real-site/)
      expect { described_class.start(real, allow_real_site: true) }.not_to raise_error
    end

    it "starts against the sandbox with no opt-in" do
      expect(described_class.start(session)).to be_a(GuidedSessionReplay)
    end
  end

  describe "step machine" do
    let(:guided) { session }
    let(:driver) { described_class.new(guided) }
    let(:replay) { driver.start(allow_real_site: false) }

    it "emits a fill instruction with the recorded field answers, never a click" do
      event(guided)
      application = create(:user_job_posting)
      guided.update!(user_job_posting: application)
      create(:application_field_answer, user_job_posting: application, field_key: "email", field_label: "Email",
                                        answer: "x@y.z", answer_source: "profile")

      instruction = driver.next_step(replay)

      expect(instruction[:action]).to eq("fill")
      expect(instruction[:fields].sole).to include(field_key: "email", field_label: "Email")
      expect(instruction[:fields].sole).not_to have_key(:answer)
    end

    it "stops at a gate and cannot be advanced past it" do
      event(guided, kind: "submission_attempted", reversibility: "irreversible", approval_state: "pending",
                    phase: "reorientation")

      expect(driver.next_step(replay)[:action]).to eq("gate")
      expect(replay.reload.status).to eq("paused_at_gate")
      expect { driver.advance(replay) }.to raise_error(described_class::Error, /gate/)
    end

    it "ends the replay when a gate is approved -- never resumes provider action" do
      event(guided, kind: "submission_attempted", reversibility: "irreversible", approval_state: "pending",
                    phase: "reorientation")
      driver.next_step(replay)

      driver.approve_gate(replay)

      expect(replay.reload).to have_attributes(status: "completed", ended_reason: /handed back/)
    end
  end
end
