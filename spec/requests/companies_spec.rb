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
  end

  describe "GET /companies/:id" do
    it "returns a success response" do
      get company_path(company)
      expect(response).to be_successful
      expect(response.body).to include("Test Corp")
    end
  end
end
