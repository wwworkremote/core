# frozen_string_literal: true

require "rails_helper"

RSpec.describe Resume::YamlImporter do
  let(:user) { create(:user) }

  # The importer consumes just3ws' published /resume.json, which is
  # `{{ site.data.resume | jsonify }}` -- the same tree the _data/resume files
  # used to be read from, keyed by the slug the files were named after. Injected
  # here rather than stubbed over HTTP so these stay unit tests.
  let(:source) do
    {
      "profile" => {
        "name" => "Mike Hall",
        "location" => { "display" => "Chicago, IL" },
        "contact" => { "email" => "mike@example.com" }
      },
      "skills" => {
        "title" => "Core Capabilities",
        "categories" => [
          { "name" => "AI-Augmented Engineering", "items" => ["LLM Orchestration", "Bounded Agent Workflows"] },
          { "name" => "Technologies", "items" => ["Ruby on Rails"] }
        ]
      },
      "positions" => {
        "activecampaign" => {
          "company" => { "name" => "ActiveCampaign", "location" => "Chicago, IL" },
          "title" => "Senior Developer",
          "type" => "Contract",
          "start_date" => "September 2018",
          "end_date" => "December 2018",
          "summary" => "Improved testability.",
          "highlights" => [{ "label" => "Quality", "text" => "Hardened test suite." }],
          "skills" => ["MySQL", "JavaScript", "Automated Testing"],
          "case_study" => {
            "challenge" => "Suite took 40 minutes.",
            "cartography_approach" => [{ "dimension" => "Test Topology", "detail" => "Mapped fixture coupling." }],
            "outcomes" => ["Cut MTTR by 60%."]
          }
        },
        # Exercises the year-only and "present" date fallbacks. start_date is an
        # Integer on purpose: a bare `start_date: 2020` survives jsonify as one,
        # and that used to raise and roll back the whole import.
        "currentco" => {
          "company" => { "name" => "CurrentCo", "location" => "Remote" },
          "title" => "Staff Engineer",
          "type" => "Full-time",
          "start_date" => 2020,
          "end_date" => "Present"
        }
      }
    }
  end

  before { ActiveJob::Base.queue_adapter = :test }

  describe ".call" do
    it "imports profile and positions correctly" do
      expect {
        described_class.call(user, source: source)
      }.to change(WorkExperience, :count).by(2)
       .and change(ExperienceHighlight, :count).by(4) # 1 highlight + challenge + dimension + outcome

      user.reload
      expect(user.name).to eq("Mike Hall")
      expect(user.career_profile.location_info["display"]).to eq("Chicago, IL")

      exp = user.career_profile.work_experiences.find_by(company_name: "ActiveCampaign")
      expect(exp.start_date).to eq(Date.new(2018, 9, 1))
    end

    it "parses a year-only start_date and treats end_date 'Present' as nil" do
      described_class.call(user, source: source)

      exp = user.career_profile.work_experiences.find_by(company_name: "CurrentCo")
      expect(exp.start_date).to eq(Date.new(2020, 1, 1))
      expect(exp.end_date).to be_nil
    end

    it "flattens skills.yml categories into the profile's skills list" do
      described_class.call(user, source: source)

      expect(user.career_profile.reload.skills)
        .to eq("LLM Orchestration, Bounded Agent Workflows, Ruby on Rails")
    end

    # The quantified outcomes live in the case_study block, not in highlights,
    # so dropping it meant the only numbers in the file were unretrievable.
    it "imports the case_study block as highlights" do
      described_class.call(user, source: source)

      exp = WorkExperience.find_by(company_name: "ActiveCampaign")
      expect(exp.experience_highlights.pluck(:label, :text))
        .to include(["Outcome", "Cut MTTR by 60%."], ["Test Topology", "Mapped fixture coupling."])
      expect(exp.embeddable_text).to include("Cut MTTR by 60%.")
    end

    it "stores each position's skills list" do
      described_class.call(user, source: source)

      exp = user.career_profile.work_experiences.find_by(company_name: "ActiveCampaign")
      expect(exp.skills).to eq("MySQL, JavaScript, Automated Testing")
    end

    # The position files carry no context/description/action/impact keys, but
    # those columns are populated from elsewhere. Reading a missing key and
    # writing the nil wiped four fields on every row, on every run.
    it "does not erase fields the YAML has no key for" do
      described_class.call(user, source: source)
      exp = user.career_profile.work_experiences.find_by(company_name: "ActiveCampaign")
      exp.update!(impact: "Cut suite runtime in half.", context: "Legacy Rails monolith.")

      described_class.call(user, source: source)

      expect(exp.reload.impact).to eq("Cut suite runtime in half.")
      expect(exp.context).to eq("Legacy Rails monolith.")
    end

    # ...but end_date must still be able to go nil: "Present" parses to nil and
    # a role that reopens has to lose its end date.
    it "still clears end_date when a role becomes current" do
      described_class.call(user, source: source)
      exp = user.career_profile.work_experiences.find_by(company_name: "CurrentCo")
      exp.update!(end_date: Date.new(2024, 1, 1))

      described_class.call(user, source: source)

      expect(exp.reload.end_date).to be_nil
    end

    # Highlights live on their own table, so replacing them changes what the
    # experience embeds without touching the experience itself. at_least(:once)
    # because the model's own after_commit fires here too -- in production the
    # job's idempotent! key collapses the pair, which the :test adapter skips.
    it "re-embeds an experience whose highlights changed" do
      described_class.call(user, source: source)
      exp = WorkExperience.find_by(company_name: "ActiveCampaign")

      expect(Resume::WorkExperienceEmbeddingJob).to have_been_enqueued.with(exp.id).at_least(:once)
    end

    # The whole point of the move off disk: with no source injected it must go
    # to the documented endpoint, not to another checkout's working tree.
    it "fetches the published endpoint when no source is injected" do
      stub = instance_double(Faraday::Response, success?: true, body: source.to_json)
      allow(Faraday).to receive(:get).with("http://just3ws.localhost/resume.json").and_return(stub)

      described_class.call(user)

      expect(Faraday).to have_received(:get).once
      expect(WorkExperience.find_by(company_name: "ActiveCampaign")).to be_present
    end

    it "raises rather than importing a partial profile when the endpoint fails" do
      stub = instance_double(Faraday::Response, success?: false, status: 503)
      allow(Faraday).to receive(:get).and_return(stub)

      expect { described_class.call(user) }.to raise_error(/returned 503/)
      expect(WorkExperience.count).to eq(0)
    end
  end
end
