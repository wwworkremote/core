# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ExtensionWorkflow" do
  describe "GET /admin/extension_workflow" do
    it "renders the workflow doc" do
      get admin_extension_workflow_path

      expect(response).to be_successful
      expect(response.body).to include("Extension Workflow")
      expect(response.body).to include("sequenceDiagram")
      expect(response.body).to include('class="mermaid"')
    end

    it "shows an empty state with no recent captures" do
      get admin_extension_workflow_path

      expect(response.body).to include("No captures in the last 7 days.")
    end

    it "rolls up capture health per provider from Captured Lead events" do
      visit = create(:ahoy_visit)
      create(:ahoy_event, visit: visit, name: "Captured Lead",
                          properties: { provider: "dice", extraction_method: "json_ld",
                                        extraction_confidence: "high", field_count: 10 })
      create(:ahoy_event, visit: visit, name: "Captured Lead",
                          properties: { provider: "dice", extraction_method: "css",
                                        extraction_confidence: "low", field_count: 4 })

      get admin_extension_workflow_path

      expect(response.body).to include("dice")
      expect(response.body).to include("50%") # 1 of 2 low-confidence
    end
  end
end
