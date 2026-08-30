# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V0::ExtensionErrorEvents" do
  def event
    { build_version: "1.31.0", event_name: "panel_open", phase: "open", provider: "greenhouse",
      page_host: "boards.greenhouse.io", error_name: "SidePanelOpenError", error_message: "boom",
      recoverable: true, context: {} }
  end

  it "records a capture failure" do
    expect do
      post "/api/v0/extension_error_events", params: { extension_error_event: event }
    end.to change(ExtensionErrorEvent, :count).by(1)

    expect(response.parsed_body).to include("success" => true)
  end

  it "stamps the guided_session_token when the failure happened during a guided session" do
    post "/api/v0/extension_error_events",
         params: { extension_error_event: event, guided_session_token: "gs_err7" }

    expect(ExtensionErrorEvent.last.guided_session_token).to eq("gs_err7")
  end
end
