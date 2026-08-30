# frozen_string_literal: true

require "rails_helper"

RSpec.describe GuidedSessionReplay do
  let(:session) do
    GuidedSession.create!(source_url: "https://wwworkremote.localhost/x", purpose: "application_execution",
                          status: "completed")
  end

  it "tracks its own lifecycle" do
    replay = session.guided_session_replays.create!

    expect(replay).to be_active
    replay.update!(status: "completed")
    expect(replay).to be_ended
  end

  # TASK-133 AC#3/#4 / Bounded Agency: no replay code path emits a click,
  # navigate, or submit -- it only ever fills.
  it "has no replay code that clicks, navigates, or submits" do
    offenders = Rails.root.glob("app/**/*replay*.rb").select do |path|
      path.read.match?(/\.click|navigate_to|submit!|press\(|dispatchEvent|\.submit\b/)
    end

    expect(offenders).to be_empty
  end
end
