# frozen_string_literal: true

require "rails_helper"

RSpec.describe Datalake::AssetStore do
  subject(:store) { described_class.new("tok_abc") }

  after { FileUtils.rm_rf(described_class::ROOT.join("tok_abc")) }

  it "writes an asset file and a manifest entry keyed to its event" do
    entry = store.write_asset(type: "dom", event_id: 42, bytes: "<html>hi</html>")

    expect(entry).to include("seq" => 1, "guided_session_event_id" => 42, "type" => "dom",
                             "path" => "0001-dom.html", "bytes" => 15)
    expect(described_class::ROOT.join("tok_abc", "0001-dom.html").read).to eq("<html>hi</html>")
    expect(store.manifest["assets"].sole["sha256"]).to eq(Digest::SHA256.hexdigest("<html>hi</html>"))
  end

  it "increments the sequence across assets" do
    store.write_asset(type: "dom", event_id: 1, bytes: "a")
    second = store.write_asset(type: "screenshot", event_id: 1, bytes: "b")

    expect(second["seq"]).to eq(2)
    expect(second["path"]).to eq("0002-screenshot.png")
  end

  it "records a capture gap without an asset file" do
    store.write_gap(type: "har", event_id: 7, reason: "debugger_detached_by_user")

    gap = store.manifest["gaps"].sole
    expect(gap).to include("guided_session_event_id" => 7, "type" => "har", "reason" => "debugger_detached_by_user")
    expect(store.manifest["assets"]).to be_empty
  end
end
