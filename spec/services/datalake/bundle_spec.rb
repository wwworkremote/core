# frozen_string_literal: true

require "rails_helper"

# ADR 010 / TASK-123 read contract.
RSpec.describe Datalake::Bundle do
  let(:token) { "bundle-spec-token" }
  let(:store) { Datalake::AssetStore.new(token) }
  let(:bundle) { described_class.for(token) }

  after do
    FileUtils.rm_rf(Datalake::AssetStore::ROOT.join(token))
    FileUtils.rm_f(Datalake::Prune::LEDGER)
  end

  it "reports whether a session captured a bundle" do
    expect(bundle).not_to be_present
    store.write_asset(type: "dom", event_id: 7, bytes: "<html></html>")
    expect(described_class.for(token)).to be_present
  end

  it "lists asset entries and filters by type and event id" do
    store.write_asset(type: "dom", event_id: 7, bytes: "<html></html>")
    store.write_asset(type: "screenshot", event_id: 7, bytes: "png-bytes")
    store.write_asset(type: "dom", event_id: 9, bytes: "<html>2</html>")

    expect(bundle.assets.size).to eq(3)
    expect(bundle.assets(type: "dom").map(&:seq)).to contain_exactly(1, 3)
    expect(bundle.assets(event_id: 7).size).to eq(2)
    expect(bundle.assets(type: "screenshot").sole).to be_screenshot
  end

  it "returns sha256-verified bytes for one asset" do
    entry = store.write_asset(type: "dom", event_id: 1, bytes: "<html>hi</html>")

    expect(bundle.read(entry["seq"])).to eq("<html>hi</html>")
  end

  it "raises for an unknown asset seq" do
    expect { bundle.read(99) }.to raise_error(described_class::Error, /no asset/)
  end

  it "raises when a file no longer matches its manifest sha256" do
    entry = store.write_asset(type: "dom", event_id: 1, bytes: "<html>original</html>")
    Datalake::AssetStore::ROOT.join(token, entry["path"]).binwrite("tampered")

    expect { described_class.for(token).read(entry["seq"]) }
      .to raise_error(described_class::Error, /sha256 mismatch/)
  end

  it "exposes capture gaps" do
    store.write_gap(type: "har", event_id: 3, reason: "debugger detached")

    expect(bundle.gaps.sole).to include("type" => "har", "reason" => "debugger detached")
  end

  it "knows a bundle was pruned rather than never captured" do
    session = GuidedSession.create!(source_url: "https://jobs.example.com/x", scenario: create(:scenario))
    session.update_columns(status: "completed", updated_at: 30.days.ago) # rubocop:disable Rails/SkipsModelValidations
    Datalake::AssetStore.new(session.session_token).write_asset(type: "dom", event_id: 1, bytes: "x")
    create(:reference_comparison, guided_session: session, scenario: session.scenario, outcome: "ok")

    Datalake::Prune.call(prune: true)
    pruned = described_class.for(session.session_token)

    expect(pruned).not_to be_present
    expect(pruned).to be_pruned
  ensure
    FileUtils.rm_rf(Datalake::AssetStore::ROOT.join(session.session_token)) if session
  end
end
