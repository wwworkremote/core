# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResumeExportService do
  let(:user) { create(:user, name: "Ada Lovelace") }
  let(:content) do
    {
      "summary" => "Pioneering engineer.",
      "experience" => [
        { "role" => "Engineer", "company" => "Analytical Engines Ltd",
          "start_date" => "2020", "end_date" => "2022", "description" => "Built things." }
      ],
      "education" => [
        { "degree" => "BSc Mathematics", "school" => "Somewhere University", "year" => "2019" }
      ]
    }
  end
  let(:resume) { Resume.create!(user: user, name: "Ada's Resume", version: 1, content: content) }
  let(:service) { described_class.new(resume) }

  before do
    skill = Skill.create!(name: "Ruby")
    resume.skills << skill
  end

  describe "#to_json" do
    it "merges resume metadata into the content" do
      parsed = JSON.parse(service.to_json)

      expect(parsed["summary"]).to eq("Pioneering engineer.")
      expect(parsed["meta"]["name"]).to eq("Ada's Resume")
      expect(parsed["meta"]["version"]).to eq(1)
      expect(parsed["meta"]["skills"]).to eq(["Ruby"])
    end
  end

  describe "#to_markdown" do
    it "renders headline sections in order" do
      markdown = service.to_markdown

      expect(markdown).to include("Pioneering engineer.")
      expect(markdown).to include("## Skills\n\nRuby")
      expect(markdown).to include("### Engineer at Analytical Engines Ltd")
      expect(markdown).to include("* **BSc Mathematics**, Somewhere University (2019)")
    end

    it "falls back to the resume owner's name when content has no name key" do
      expect(service.to_markdown).to include("# Ada Lovelace")
    end

    it "prefers content['name'] over the resume owner's name when present" do
      resume.update!(content: content.merge("name" => "Custom Header"))
      expect(described_class.new(resume).to_markdown).to include("# Custom Header")
    end
  end

  describe "#to_text" do
    it "strips markdown heading and bold markers from the markdown rendering" do
      text = service.to_text

      expect(text).not_to include("#")
      expect(text).not_to include("**")
      expect(text).to include("Engineer at Analytical Engines Ltd")
    end
  end

  describe "#to_mcp" do
    it "returns a structured JSON payload for LLM context" do
      parsed = JSON.parse(service.to_mcp)

      expect(parsed["role"]).to eq("resume")
      expect(parsed["identifier"]).to eq("Ada's Resume_v1")
      expect(parsed["data"]).to eq(service.to_markdown)
      expect(parsed["skills"]).to eq(["Ruby"])
    end
  end
end
