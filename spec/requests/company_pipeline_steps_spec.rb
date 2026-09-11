# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::CompanyPipelineSteps" do
  let!(:company) { create(:company) }

  describe "POST /admin/companies/:company_id/company_pipeline_steps" do
    it "changes the company status using an event" do
      post admin_company_company_pipeline_steps_path(company), params: { status: "favorite" }

      expect(response).to redirect_to(admin_company_path(company))
      company.reload
      expect(company.status).to eq("favorited")
      expect(company.company_pipeline_steps.count).to eq(1)
    end

    it "adds a research note" do
      expect {
        post admin_company_company_pipeline_steps_path(company), params: { note: "Some research note" }
      }.to change(company.company_pipeline_steps, :count).by(1)

      expect(response).to redirect_to(admin_company_path(company))
      expect(company.company_pipeline_steps.last.note).to eq("Some research note")
    end
  end
end
