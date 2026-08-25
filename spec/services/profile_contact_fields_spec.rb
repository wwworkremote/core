# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfileContactFields do
  it "prefers the dedicated github_url column over contact_info's nested value" do
    user = create(:user)
    create(:career_profile, user: user, github_url: "https://github.com/canonical",
                            contact_info: { "github" => { "url" => "https://github.com/fallback" } })

    expect(described_class.call(user)[:github_url]).to eq("https://github.com/canonical")
  end

  # ATS forms routinely split the address instead of taking one string, and
  # location_info already holds the parts.
  it "surfaces the split address parts alongside the combined display string" do
    user = create(:user)
    create(:career_profile, user: user,
                            location_info: { "display" => "Chicago, IL", "locality" => "Chicago",
                                             "region" => "IL", "country" => "United States" })

    expect(described_class.call(user)).to include(
      location: "Chicago, IL", city: "Chicago", state: "IL", country: "United States"
    )
  end

  it "returns nils for every field when the user has no career profile" do
    user = create(:user, name: "No Profile")

    expect(described_class.call(user)).to eq(
      name: "No Profile", first_name: "No", middle_name: nil, last_name: "Profile",
      preferred_name: nil, email: nil, phone: nil, github_url: nil, linkedin_url: nil,
      website_url: nil, location: nil, city: nil, state: nil, country: nil
    )
  end

  it "preserves structured legal and preferred names when supplied by the canonical profile" do
    user = create(:user, name: "Display Name")
    create(:career_profile, user: user, contact_info: {
      "name_parts" => { "first" => "Legal", "middle" => "Middle", "last" => "Family",
                         "preferred_name" => "Display" }
    })

    expect(described_class.call(user)).to include(
      first_name: "Legal", middle_name: "Middle", last_name: "Family", preferred_name: "Display"
    )
  end
end
