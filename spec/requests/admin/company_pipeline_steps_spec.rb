# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::CompanyPipelineSteps" do
  let!(:company) { create(:company) }

  describe "POST /admin/companies/:company_id/company_pipeline_steps" do
    it "logs a status change" do
      expect {
        post admin_company_company_pipeline_steps_path(company), params: { status: "favorite" }
      }.to change(CompanyPipelineStep, :count).by(1)

      expect(response).to redirect_to(admin_company_path(company))
      expect(company.reload.status).to eq("favorited")
    end

    it "logs a research note" do
      expect {
        post admin_company_company_pipeline_steps_path(company), params: { note: "High growth potential", link: "https://news.com" }
      }.to change(CompanyPipelineStep, :count).by(1)

      step = CompanyPipelineStep.last
      expect(step.note).to eq("High growth potential")
      expect(step.link).to eq("https://news.com")
    end

    it "ignores unwhitelisted status events" do
      expect {
        post admin_company_company_pipeline_steps_path(company), params: { status: "destroy" }
      }.not_to change(CompanyPipelineStep, :count)
    end
  end
end
