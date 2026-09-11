# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies" do
  let!(:company) { create(:company, name: "Test Corp") }
  let(:user) { create(:user) }

  before { create(:job_posting, company: company) }

  describe "GET /companies" do
    it "returns a success response" do
      get companies_path
      expect(response).to be_successful
      expect(response.body).to include("Test Corp")
    end

    it "shows a cooldown badge for a company still within its decline cooldown" do
      company.update!(last_declined_at: 1.month.ago)
      get companies_path
      expect(response.body).to include("Cooldown")
    end

    it "omits the cooldown badge once the cooldown has ended" do
      company.update!(last_declined_at: 7.months.ago)
      get companies_path
      expect(response.body).not_to include("Cooldown")
    end

    it "searches and filters companies" do
      create(:company, name: "Other Corp", toxic_culture_flag: true)

      get companies_path, params: { q: "Test", active: "1" }

      expect(response.body).to include("Test Corp")
      expect(response.body).not_to include("Other Corp")
    end
  end

  describe "GET /companies/:id" do
    it "returns a success response" do
      get company_path(company)
      expect(response).to be_successful
      expect(response.body).to include("Test Corp")
    end

    it "shows the cooldown-until date on the company's own page" do
      company.update!(last_declined_at: Time.zone.parse("2026-04-01"))
      get company_path(company)
      expect(response.body).to include("cooldown until")
    end

    it "shows harness activity once an application for the company has been processed" do
      posting = create(:job_posting, company: company)
      application = User.find_or_create_by!(email: "mike@just3ws.com") { |u| u.name = "mike"; u.password = "password" }
                        .user_job_postings.create!(job_posting: posting)
      GuidedSession.create!(source_url: "https://boards.greenhouse.io/acme/jobs/1", purpose: "application_execution",
                            user_job_posting: application, status: "completed")

      get company_path(company)

      expect(response.body).to include("Harness activity").and include("1 supervised application")
    end
  end
end
