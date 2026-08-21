# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V0::Profile" do
  describe "GET /api/v0/profile" do
    let(:user) { create(:user, name: "Mike Hall") }
    let(:contact_info) do
      { "email" => "mike@just3ws.com", "phone" => "(847) 877-3825",
        "linkedin" => { "url" => "https://www.linkedin.com/in/just3ws/" } }
    end

    before { allow(User).to receive(:first).and_return(user) }

    it "returns flattened contact fields for the extension to copy-paste" do
      create(:career_profile, user: user, github_url: "https://github.com/just3ws",
                              contact_info: contact_info, location_info: { "display" => "Chicago, IL" })

      get api_v0_profile_path, as: :json

      json = response.parsed_body
      expect(json).to include(
        "name" => "Mike Hall",
        "email" => "mike@just3ws.com",
        "github_url" => "https://github.com/just3ws",
        "linkedin_url" => "https://www.linkedin.com/in/just3ws/",
        "location" => "Chicago, IL"
      )
    end

    it "returns nils gracefully when there is no career profile yet" do
      get api_v0_profile_path, as: :json

      expect(response).to be_successful
      expect(response.parsed_body["email"]).to be_nil
    end
  end
end
