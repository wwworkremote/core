# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfileContactFields do
  it "prefers the dedicated github_url column over contact_info's nested value" do
    user = create(:user)
    create(:career_profile, user: user, github_url: "https://github.com/canonical",
                            contact_info: { "github" => { "url" => "https://github.com/fallback" } })

    expect(described_class.call(user)[:github_url]).to eq("https://github.com/canonical")
  end

  it "returns nils for every field when the user has no career profile" do
    user = create(:user, name: "No Profile")

    expect(described_class.call(user)).to eq(
      name: "No Profile", email: nil, phone: nil, github_url: nil, linkedin_url: nil, website_url: nil, location: nil
    )
  end
end
