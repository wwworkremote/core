# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resume::YamlImporter do
  let(:user) { create(:user) }
  let(:base_path) { Rails.root.join("spec/fixtures/resume") }

  before do
    stub_const("Resume::YamlImporter::BASE_PATH", base_path.to_s)
    FileUtils.mkdir_p(base_path.join("positions"))

    # Mock profile.yml
    File.write(base_path.join("profile.yml"), {
      "name" => "Mike Hall",
      "location" => { "display" => "Chicago, IL" },
      "contact" => { "email" => "mike@example.com" }
    }.to_yaml)

    # Mock a position
    File.write(base_path.join("positions", "activecampaign.yml"), {
      "company" => { "name" => "ActiveCampaign", "location" => "Chicago, IL" },
      "title" => "Senior Developer",
      "type" => "Contract",
      "start_date" => "September 2018",
      "end_date" => "December 2018",
      "summary" => "Improved testability.",
      "highlights" => [{ "label" => "Quality", "text" => "Hardened test suite." }]
    }.to_yaml)

    # Mock a position exercising the year-only and "present" date fallbacks
    File.write(base_path.join("positions", "currentco.yml"), {
      "company" => { "name" => "CurrentCo", "location" => "Remote" },
      "title" => "Staff Engineer",
      "type" => "Full-time",
      "start_date" => "2020",
      "end_date" => "Present"
    }.to_yaml)
  end

  after do
    FileUtils.rm_rf(base_path)
  end

  describe ".call" do
    it "imports profile and positions correctly" do
      expect {
        described_class.call(user, base_path: base_path.to_s)
      }.to change(WorkExperience, :count).by(2)
       .and change(ExperienceHighlight, :count).by(1)

      user.reload
      expect(user.name).to eq("Mike Hall")
      expect(user.career_profile.location_info["display"]).to eq("Chicago, IL")

      exp = user.career_profile.work_experiences.find_by(company_name: "ActiveCampaign")
      expect(exp.start_date).to eq(Date.new(2018, 9, 1))
    end

    it "parses a year-only start_date and treats end_date 'Present' as nil" do
      described_class.call(user, base_path: base_path.to_s)

      exp = user.career_profile.work_experiences.find_by(company_name: "CurrentCo")
      expect(exp.start_date).to eq(Date.new(2020, 1, 1))
      expect(exp.end_date).to be_nil
    end
  end
end
