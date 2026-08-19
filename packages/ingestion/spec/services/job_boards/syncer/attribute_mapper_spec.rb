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

  describe "adp mapping" do
    it "maps a direct-hiring-page ADP requisition onto the job posting" do
      data = {
        "publishedJobTitle" => "Product Onboarding Specialist", "jobDescription" => "<p>Do the thing</p>",
        "target_url" => "https://myjobs.adp.com/corpfollettexternal/cx/job-details?reqId=5001218021506",
        "postingDate" => "2026-08-10", "client_name" => "Follett Corporation", "location" => "Westchester, IL"
      }

      described_class.call(job_posting, data, "adp")

      expect(job_posting.title).to eq("Product Onboarding Specialist")
      expect(job_posting.company).to eq("Follett Corporation")
      expect(job_posting.location).to eq("Westchester, IL")
      expect(job_posting.target_url).to eq(data["target_url"])
      expect(job_posting.body).to include("Do the thing")
    end
  end

  describe "workday mapping" do
    it "maps a direct-hiring-page Workday requisition onto the job posting" do
      data = {
        "title" => "Staff Engineer - Software", "jobDescription" => "<p>Lead the platform</p>",
        "target_url" => "https://myhrhome.wd1.myworkdayjobs.com/OneMainCareers/job/Baltimore-MD/Staff-Engineer_R1",
        "company" => "OneMain General Services Corporation", "location" => "Baltimore, MD",
        "employment_type" => "Full time"
      }

      described_class.call(job_posting, data, "workday")

      expect(job_posting.title).to eq("Staff Engineer - Software")
      expect(job_posting.company).to eq("OneMain General Services Corporation")
      expect(job_posting.location).to eq("Baltimore, MD")
      expect(job_posting.target_url).to eq(data["target_url"])
      expect(job_posting.body).to include("Lead the platform")
      expect(job_posting.data["employment_type"]).to eq("Full time")
    end
  end

  describe "rubyonrails mapping" do
    it "splits company out of the 'Title at Company' RSS title" do
      data = {
        "title" => "Senior Backend Engineer, remote at Acme Corp",
        "description" => "<p>Build things.</p>",
        "link" => "https://jobs.rubyonrails.org/jobs/1-senior-backend-engineer-acme-corp",
        "pub_date" => "Mon, 17 Aug 2026 19:06:59 +0000"
      }

      described_class.call(job_posting, data, "rubyonrails")

      expect(job_posting.title).to eq("Senior Backend Engineer, remote")
      expect(job_posting.company).to eq("Acme Corp")
      expect(job_posting.target_url).to eq(data["link"])
      expect(job_posting.body).to include("Build things")
    end

    it "still extracts a usable company from a garbled duplicate-suffix title" do
      data = { "title" => "Rails Developer at Podomatic at Podomatic" }

      described_class.call(job_posting, data, "rubyonrails")

      expect(job_posting.title).to eq("Rails Developer")
      expect(job_posting.company).to eq("Podomatic")
    end
  end
end
