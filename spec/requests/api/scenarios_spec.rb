# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Scenario capture API" do
  let(:posting_source) { '<form data-job-post-id="job-1"></form>' }
  let(:confirmation_source) { '<div data-ats-application-id="application-1"></div>' }

  it "creates and then appends to a Scenario using the capture token" do
    post api_scenarios_path, params: { provider: "greenhouse", source: posting_source }

    expect(response).to have_http_status(:created)
    token = response.parsed_body.fetch("scenario_token")

    expect do
      post api_scenarios_path, params: {
        provider: "greenhouse", scenario_token: token, source: confirmation_source
      }
    end.to change(ScenarioSignature, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(Scenario.find_by!(scenario_token: token).scenario_signatures.pluck(:kind, :value)).to contain_exactly(
      %w[job_post_id job-1], %w[ats_application_id application-1]
    )
  end
end
