# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resume::PersonaContext do
  let(:source) do
    {
      "archetypes" => {
        "staff_platform" => {
          "short_label" => "Staff Platform", "title" => "Staff Platform Engineer",
          "target_tier" => "staff", "summary" => "Platform summary",
          "core_skills" => ["Ruby"], "featured_positions" => [{ "id" => "role-a" }],
          "additional_experience" => [], "selected_projects" => []
        }
      },
      "positions" => {
        "role-a" => { "id" => "role-a", "title" => "Engineer", "company" => { "name" => "Acme" } }
      }
    }
  end

  it "lists canonical persona metadata" do
    expect(described_class.personas(source: source)).to contain_exactly(
      include(id: "staff_platform", label: "Staff Platform", title: "Staff Platform Engineer")
    )
  end

  it "resolves featured position references into the application snapshot" do
    expect(described_class.call("staff_platform", source: source)).to include(
      "id" => "staff_platform", "positions" => [source["positions"]["role-a"]]
    )
  end
end
