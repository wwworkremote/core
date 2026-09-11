# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobPosting::LegacyCompanyAccess do
  describe "#company_record" do
    it "returns the resolved Company directly when company_id is set" do
      company = create(:company)
      job_posting = create(:job_posting, company_id: company.id)

      expect(job_posting.company_record).to eq(company)
    end

    it "looks up by name when only the legacy string is set" do
      company = create(:company, name: "Acme Corp")
      job_posting = create(:job_posting, company: "Acme Corp")

      expect(job_posting.company_record).to eq(company)
    end

    it "returns nil when no Company matches the legacy string" do
      job_posting = create(:job_posting, company: "Nobody Ever Heard Of Inc")

      expect(job_posting.company_record).to be_nil
    end
  end

  describe "#company" do
    it "returns the Company record when company_id is set" do
      company = create(:company)
      job_posting = create(:job_posting, company_id: company.id)

      expect(job_posting.company).to eq(company)
    end

    it "returns the plain string when only company_name is set" do
      job_posting = create(:job_posting, company: "Acme Corp")

      expect(job_posting.company).to eq("Acme Corp")
    end
  end
end
