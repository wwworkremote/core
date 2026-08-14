# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::Syncer::AttributeMapper do
  let(:job_posting) { JobPosting.new }

  describe "employment_type normalization" do
    it "derives employment_type from Adzuna's contract_time" do
      data = { "title" => "Ruby Dev", "contract_time" => "full_time" }

      described_class.call(job_posting, data, "adzuna")

      expect(job_posting.data["employment_type"]).to eq("full_time")
    end

    it "derives employment_type from Lever's categories.commitment" do
      data = { "text" => "Ruby Dev", "categories" => { "commitment" => "Contract" } }

      described_class.call(job_posting, data, "lever")

      expect(job_posting.data["employment_type"]).to eq("Contract")
    end

    it "derives employment_type from Remotive's job_type" do
      data = { "title" => "Ruby Dev", "job_type" => "contract" }

      described_class.call(job_posting, data, "remotive")

      expect(job_posting.data["employment_type"]).to eq("contract")
    end

    it "derives employment_type from Jobicy's jobType array" do
      data = { "jobTitle" => "Ruby Dev", "jobType" => ["Full-Time"] }

      described_class.call(job_posting, data, "jobicy")

      expect(job_posting.data["employment_type"]).to eq("Full-Time")
    end

    it "derives employment_type from Arbeitnow's job_types array" do
      data = { "title" => "Ruby Dev", "job_types" => ["Contract"] }

      described_class.call(job_posting, data, "arbeitnow")

      expect(job_posting.data["employment_type"]).to eq("Contract")
    end

    it "does not overwrite an employment_type already present on the payload" do
      data = { "title" => "Ruby Dev", "contract_time" => "full_time", "employment_type" => "CONTRACTOR" }

      described_class.call(job_posting, data, "adzuna")

      expect(job_posting.data["employment_type"]).to eq("CONTRACTOR")
    end

    it "leaves employment_type unset for providers with no known signal" do
      data = { "title" => "Ruby Dev" }

      described_class.call(job_posting, data, "greenhouse")

      expect(job_posting.data["employment_type"]).to be_nil
    end
  end
end
