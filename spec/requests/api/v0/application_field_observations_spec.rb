# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V0::ApplicationFieldObservations" do
  let(:user) { create(:user) }
  let(:job_posting) { create(:job_posting) }

  before { allow(User).to receive(:first).and_return(user) }

  def observation
    { field_key: "workday:email:0", field_label: "Email", field_type: "email",
      page_url: "https://example.workday.com/apply", context: { required: true } }
  end

  it "records observed fields against the tracked application" do
    expect do
      post "/api/v0/job_postings/#{job_posting.id}/application_field_observations",
           params: { observations: [observation] }
    end.to change(ApplicationFieldObservation, :count).by(1)

    expect(response).to have_http_status(:ok)
  end

  it "stamps the guided_session_token when the scan came from a guided session" do
    post "/api/v0/job_postings/#{job_posting.id}/application_field_observations",
         params: { guided_session_token: "gs_obs42", observations: [observation] }

    expect(ApplicationFieldObservation.last.guided_session_token).to eq("gs_obs42")
  end

  it "leaves guided_session_token nil for a non-guided scan" do
    post "/api/v0/job_postings/#{job_posting.id}/application_field_observations",
         params: { observations: [observation] }

    expect(ApplicationFieldObservation.last.guided_session_token).to be_nil
  end
end
