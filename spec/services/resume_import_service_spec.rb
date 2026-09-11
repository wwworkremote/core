# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResumeImportService do
  let(:user) do
    User.find_or_create_by!(email: ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com")) do |u|
      u.name = ENV.fetch("ADMIN_NAME", "mike")
      u.password = ENV.fetch("ADMIN_PASSWORD", "password")
    end
  end
  let(:service) { described_class.new(user) }

  describe "#from_url" do
    it "returns nil when the fetch is unsuccessful" do
      stub_request(:get, "https://example.com/resume.json").to_return(status: 500)

      expect(service.from_url("https://example.com/resume.json")).to be_nil
    end

    it "parses just3ws.github.io JSON into the standardized schema" do
      body = { "basics" => { "name" => "Mike", "summary" => "Engineer" },
               "work" => [{ "company" => "Acme" }], "education" => ["MIT"],
               "skills" => [{ "name" => "Ruby" }, { "name" => "Rails" }] }.to_json
      stub_request(:get, "https://just3ws.github.io/resume.json").to_return(status: 200, body: body)

      resume = service.from_url("https://just3ws.github.io/resume.json")

      expect(resume.content["name"]).to eq("Mike")
      expect(resume.content["summary"]).to eq("Engineer")
      expect(resume.content["experience"]).to eq([{ "company" => "Acme" }])
      expect(resume.content["skills_names"]).to eq(%w[Ruby Rails])
    end

    it "parses .json urls even off the just3ws domain" do
      body = { "name" => "Mike", "summary" => "Engineer" }.to_json
      stub_request(:get, "https://example.com/data.json").to_return(status: 200, body: body)

      resume = service.from_url("https://example.com/data.json")

      expect(resume.content["name"]).to eq("Mike")
    end

    it "falls back to raw body storage when JSON parsing fails on a json-shaped url" do
      stub_request(:get, "https://just3ws.github.io/resume.json").to_return(status: 200, body: "not json")

      resume = service.from_url("https://just3ws.github.io/resume.json")

      expect(resume.content["summary"]).to eq("Imported from https://just3ws.github.io/resume.json")
      expect(resume.content["raw_body"]).to eq("not json")
    end

    it "falls back to raw body storage for non-JSON urls" do
      stub_request(:get, "https://example.com/resume.html").to_return(status: 200, body: "<html>Resume</html>")

      resume = service.from_url("https://example.com/resume.html")

      expect(resume.content["summary"]).to eq("Imported from https://example.com/resume.html")
      expect(resume.content["raw_body"]).to eq("<html>Resume</html>")
    end

    it "auto-increments the version for repeated imports under the same name" do
      stub_request(:get, "https://example.com/r").to_return(status: 200, body: "raw")

      first = service.from_url("https://example.com/r", name: "My Resume")
      second = service.from_url("https://example.com/r", name: "My Resume")

      expect(first.version).to eq(1)
      expect(second.version).to eq(2)
    end
  end
end
