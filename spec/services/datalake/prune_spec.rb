# frozen_string_literal: true

require "rails_helper"

# ADR 010 curation + prune.
RSpec.describe Datalake::Prune do
  let(:scenario) { create(:scenario) }

  after do
    FileUtils.rm_rf(Datalake::AssetStore::ROOT)
    FileUtils.rm_f(Datalake::Prune::LEDGER)
  end

  def bundle_for(session)
    store = Datalake::AssetStore.new(session.session_token)
    store.write_asset(type: "dom", event_id: 1, bytes: "<html></html>")
    store
  end

  def session(status: "completed", curated: true, completed_days_ago: 30)
    s = GuidedSession.create!(source_url: "https://jobs.example.com/x", status: status,
                              scenario: curated ? scenario : nil)
    s.update_column(:updated_at, completed_days_ago.days.ago) # rubocop:disable Rails/SkipsModelValidations
    bundle_for(s)
    s
  end

  def verdict(token) = described_class.call.find { |r| r.session_token == token }.verdict

  it "keeps a bundle whose session has not completed" do
    s = session(status: "active")
    expect(verdict(s.session_token)).to eq(:keep)
  end

  it "keeps a completed session that was never curated into a Scenario" do
    s = session(curated: false)
    expect(verdict(s.session_token)).to eq(:keep)
  end

  it "keeps a curated session still inside the grace window" do
    s = session(completed_days_ago: 2)
    expect(verdict(s.session_token)).to eq(:keep)
  end

  it "marks a curated, grace-elapsed session with drift findings prune_eligible" do
    s = session
    comparison = create(:reference_comparison, guided_session: s, scenario: scenario, outcome: "ok")
    create(:comparison_finding, reference_comparison: comparison)

    expect(verdict(s.session_token)).to eq(:prune_eligible)
  end

  it "marks a curated, grace-elapsed session with a clean reference match prune_first" do
    s = session
    create(:reference_comparison, guided_session: s, scenario: scenario, outcome: "ok")

    expect(verdict(s.session_token)).to eq(:prune_first)
  end

  it "marks a bundle directory with no guided session an orphan" do
    Datalake::AssetStore.new("orphan-token").write_asset(type: "dom", event_id: 1, bytes: "x")
    expect(verdict("orphan-token")).to eq(:orphan)
  end

  it "deletes prunable bundles and records them in the ledger only when prune: true" do
    keep = session(completed_days_ago: 1)
    gone = session
    create(:reference_comparison, guided_session: gone, scenario: scenario, outcome: "ok")

    described_class.call(prune: true)

    expect(Datalake::AssetStore::ROOT.join(gone.session_token)).not_to exist
    expect(Datalake::AssetStore::ROOT.join(keep.session_token)).to exist
    ledger = JSON.parse(Datalake::Prune::LEDGER.read)
    expect(ledger.sole).to include("session_token" => gone.session_token, "verdict" => "prune_first")
  end

  it "does not touch disk on a dry run" do
    s = session
    create(:reference_comparison, guided_session: s, scenario: scenario, outcome: "ok")

    described_class.call

    expect(Datalake::AssetStore::ROOT.join(s.session_token)).to exist
    expect(Datalake::Prune::LEDGER).not_to exist
  end
end
