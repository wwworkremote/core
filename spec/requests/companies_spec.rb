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
  end
end
