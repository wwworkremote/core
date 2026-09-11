# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ExtractionRules" do
  describe "GET /admin/extraction_rules" do
    it "lists rules ordered by provider then field_name" do
      create(:extraction_rule, provider: "linkedin", field_name: "title")
      create(:extraction_rule, provider: "indeed", field_name: "title")

      get admin_extraction_rules_path

      expect(response).to be_successful
      indeed_index = response.body.index("indeed")
      linkedin_index = response.body.index("linkedin")
      expect(indeed_index).to be < linkedin_index
    end
  end

  describe "GET /admin/extraction_rules/:id" do
    it "shows the rule and its observations, most recent first" do
      rule = create(:extraction_rule, provider: "linkedin", field_name: "title", selector: "h1#job-title")
      older = ExtractionRuleObservation.create!(provider: "linkedin", field_name: "title",
                                                learned_selector: "h1.old", created_at: 2.days.ago)
      newer = ExtractionRuleObservation.create!(provider: "linkedin", field_name: "title",
                                                learned_selector: "h1#job-title", created_at: 1.hour.ago)

      get admin_extraction_rule_path(rule)

      expect(response).to be_successful
      older_index = response.body.index(older.learned_selector)
      newer_index = response.body.index(newer.learned_selector)
      expect(newer_index).to be < older_index
    end
  end
end
