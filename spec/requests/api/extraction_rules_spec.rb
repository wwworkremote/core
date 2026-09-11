# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::ExtractionRules" do
  describe "GET /api/extraction_rules" do
    it "returns only the requested provider's rules" do
      create(:extraction_rule, provider: "linkedin", field_name: "title", selector: "h1.linkedin-title")
      create(:extraction_rule, provider: "indeed", field_name: "title", selector: "h1.indeed-title")

      get api_extraction_rules_path, params: { provider: "linkedin" }

      expect(response).to be_successful
      assert_schema_conform(200)
      body = response.parsed_body
      expect(body.length).to eq(1)
      expect(body.first["field_name"]).to eq("title")
      expect(body.first["selector"]).to eq("h1.linkedin-title")
    end

    it "returns an empty array for a provider with no taught rules" do
      get api_extraction_rules_path, params: { provider: "wellfound" }

      expect(response).to be_successful
      expect(response.parsed_body).to eq([])
    end
  end

  describe "POST /api/extraction_rules" do
    let(:learner) { instance_double(JobBoards::SelectorLearnerAgent, call: "h1#job-title") }

    before do
      allow(JobBoards::SelectorLearnerAgent).to receive(:new).and_return(learner)
    end

    it "creates a new rule via the learner agent" do
      post api_extraction_rules_path, as: :json, params: {
        provider: "linkedin", field_name: "title",
        element_html: "<h1 id=\"job-title\">Staff Engineer</h1>",
        parent_html: "<div><h1 id=\"job-title\">Staff Engineer</h1></div>",
        candidate_selector: "h1.top-card-layout__title:nth-of-type(1)",
        source_url: "https://www.linkedin.com/jobs/view/123"
      }

      expect(response).to be_successful
      assert_schema_conform(200)
      expect(response.parsed_body["selector"]).to eq("h1#job-title")

      rule = ExtractionRule.find_by(provider: "linkedin", field_name: "title")
      expect(rule.selector).to eq("h1#job-title")
      expect(rule.source_url).to eq("https://www.linkedin.com/jobs/view/123")
    end

    it "logs the candidate and learned selectors as an observation" do
      post api_extraction_rules_path, params: {
        provider: "linkedin", field_name: "title",
        element_html: "<h1 id=\"job-title\">Staff Engineer</h1>",
        parent_html: "<div><h1 id=\"job-title\">Staff Engineer</h1></div>",
        candidate_selector: "h1.top-card-layout__title:nth-of-type(1)",
        source_url: "https://www.linkedin.com/jobs/view/123"
      }

      observation = ExtractionRuleObservation.find_by(provider: "linkedin", field_name: "title")
      expect(observation.candidate_selector).to eq("h1.top-card-layout__title:nth-of-type(1)")
      expect(observation.learned_selector).to eq("h1#job-title")
      expect(observation.source_url).to eq("https://www.linkedin.com/jobs/view/123")
    end

    it "upserts the rule on re-teach instead of creating a duplicate" do
      create(:extraction_rule, provider: "linkedin", field_name: "title", selector: "h1.old")

      post api_extraction_rules_path, params: {
        provider: "linkedin", field_name: "title",
        element_html: "<h1 id=\"job-title\">Staff Engineer</h1>",
        parent_html: "<div></div>", candidate_selector: "h1"
      }

      expect(ExtractionRule.where(provider: "linkedin", field_name: "title").count).to eq(1)
      expect(ExtractionRule.find_by(provider: "linkedin", field_name: "title").selector).to eq("h1#job-title")
    end

    it "logs a new observation on every teach, even repeated ones for the same field" do
      2.times do
        post api_extraction_rules_path, params: {
          provider: "linkedin", field_name: "title",
          element_html: "<h1 id=\"job-title\">Staff Engineer</h1>",
          parent_html: "<div></div>", candidate_selector: "h1"
        }
      end

      expect(ExtractionRuleObservation.where(provider: "linkedin", field_name: "title").count).to eq(2)
    end
  end
end
