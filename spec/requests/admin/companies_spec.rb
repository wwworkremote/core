# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Companies" do
  describe "POST /admin/companies/:id/toggle_ingestion" do
    it "resumes ingestion when currently disabled" do
      company = create(:company, ingestion_enabled: false)

      post toggle_ingestion_admin_company_path(company)

      expect(company.reload.ingestion_enabled).to be true
      expect(response).to redirect_to(admin_companies_path)
      expect(flash[:notice]).to eq("Ingestion resumed for #{company.name}.")
    end

    it "disables ingestion and purges existing job postings when currently enabled" do
      company = create(:company, ingestion_enabled: true)
      posting = create(:job_posting, company_id: company.id, status: "none")
      already_purged = create(:job_posting, company_id: company.id, status: "purged", signature: "already-purged")

      post toggle_ingestion_admin_company_path(company)

      expect(company.reload.ingestion_enabled).to be false
      expect(posting.reload.status).to eq("purged")
      expect(already_purged.reload.updated_at).to eq(already_purged.created_at)
      expect(flash[:notice]).to eq(
        "Ingestion disabled for #{company.name} and all existing postings have been purged."
      )
    end
  end
end
