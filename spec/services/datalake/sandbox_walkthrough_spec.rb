# frozen_string_literal: true

require "rails_helper"

# TASK-126 AC#8.
RSpec.describe Datalake::SandboxWalkthrough do
  it "produces a manifest with one asset per event, a capture gap, and event pointers" do
    report = described_class.call

    expect(report[:assets]).to eq(3)
    expect(report[:gaps]).to eq(1)
    expect(report[:every_event_pointed]).to be(true)
  end

  it "leaves no bundle directory behind" do
    report = described_class.call

    expect(Datalake::AssetStore::ROOT.join(report[:session_token])).not_to exist
  end
end
