# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::DatalakeAssets" do
  let(:session) { GuidedSession.create!(source_url: "https://jobs.example.com/x", purpose: "application_execution") }
  let(:event) do
    session.guided_session_events.create!(kind: "application_page_arrived", action: "a", intent: "i",
                                          requirement: "required", reversibility: "reversible",
                                          approval_state: "not_required", phase: "resolution",
                                          occurred_at: Time.current)
  end

  after { FileUtils.rm_rf(Datalake::AssetStore::ROOT.join(session.session_token)) }

  it "stores a base64 DOM asset under the session token and returns the manifest entry" do
    dom = Base64.strict_encode64("<html>x</html>")
    post "/api/guided_sessions/#{session.session_token}/datalake_assets", params: {
      asset: { type: "dom", guided_session_event_id: event.id, content_base64: dom }
    }

    expect(response).to have_http_status(:created)
    entry = response.parsed_body["asset"]
    expect(entry).to include("type" => "dom", "guided_session_event_id" => event.id)
    expect(Datalake::AssetStore::ROOT.join(session.session_token, entry["path"]).read).to eq("<html>x</html>")
  end

  it "records a capture gap" do
    post "/api/guided_sessions/#{session.session_token}/datalake_assets", params: {
      gap: { type: "har", guided_session_event_id: event.id, reason: "onDetach canceled_by_user" }
    }

    expect(response).to have_http_status(:created)
    expect(Datalake::AssetStore.new(session.session_token).manifest["gaps"].sole["type"]).to eq("har")
  end

  it "rejects an unknown asset type" do
    post "/api/guided_sessions/#{session.session_token}/datalake_assets", params: {
      asset: { type: "video", guided_session_event_id: event.id, content_base64: "AA==" }
    }

    expect(response).to have_http_status(:unprocessable_content)
  end
end
