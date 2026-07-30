# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::Syncer::CompanyResolver do
  # CompanyResolver only mutates the AASM status in memory -- Syncer is
  # responsible for persisting afterward (calling #ignore alone does not
  # save; confirmed AASM's non-bang event here leaves the record dirty),
  # so these assertions check the in-memory attribute, not a reloaded one.
  describe ".call" do
    it "creates the company and does not ignore the posting for an ordinary company" do
      posting = create(:job_posting, company_name: "Acme Corp", status: "none")

      described_class.call(posting)

      company = Company.find_by(name: "Acme Corp")
      expect(company.ingestion_enabled).to be true
      expect(posting.status).to eq("none")
    end

    it "creates a new big-tech company with ingestion disabled and ignores the posting" do
      posting = create(:job_posting, company_name: "Meta Platforms", status: "none")

      described_class.call(posting)

      company = Company.find_by(name: "Meta Platforms")
      expect(company.ingestion_enabled).to be false
      expect(posting.status).to eq("ignored")
    end

    it "ignores postings for an existing company with ingestion already disabled" do
      create(:company, name: "Acme Corp", ingestion_enabled: false)
      posting = create(:job_posting, company_name: "Acme Corp", status: "none")

      described_class.call(posting)

      expect(posting.status).to eq("ignored")
    end
  end
end
