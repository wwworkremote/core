# frozen_string_literal: true

require "rails_helper"

# TASK-126 AC#8 / TASK-134 AC#4.
RSpec.describe Datalake::SandboxWalkthrough do
  it "gives an application_execution bundle har + full-page screenshot asset types and a detach gap" do
    execution = described_class.call[:execution]

    expect(execution[:asset_types]).to eq(%w[dom har screenshot])
    expect(execution[:gaps]).to eq(1)
    expect(execution[:every_event_pointed]).to be(true)
  end

  it "gives an application_research bundle only the light set -- no har, no gap" do
    research = described_class.call[:research]

    expect(research[:asset_types]).to eq(%w[dom screenshot])
    expect(research[:gaps]).to eq(0)
    expect(research[:every_event_pointed]).to be(true)
  end

  it "leaves no bundle directory behind" do
    report = described_class.call

    expect(Datalake::AssetStore::ROOT.join(report[:execution][:session_token])).not_to exist
    expect(Datalake::AssetStore::ROOT.join(report[:research][:session_token])).not_to exist
  end
end
