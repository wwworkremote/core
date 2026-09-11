# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::IndeedRowImporter do
  let(:user) { create(:user) }
  let(:row) do
    { "jobKey" => "abc123", "jobUrl" => "https://www.indeed.com/viewjob?jk=abc123", "jobTitle" => "Staff Engineer",
      "company" => { "name" => "Acme" }, "location" => "Remote", "applyTime" => 1_754_006_400_000,
      "statuses" => {} }
  end

  describe "#call" do
    it "creates a JobPosting and an applied UserJobPosting with an exact applied_at" do
      result = described_class.call(row, user: user)

      expect(result[:posting]).to be_persisted
      tracked = user.user_job_postings.find_by(job_posting: result[:posting])
      expect(tracked.status).to eq("applied")
      expect(tracked.applied_at).to eq(Time.zone.at(1_754_006_400_000 / 1000))
    end

    it "matches an existing posting via the jk= native id fragment" do
      existing = create(:job_posting, target_url: "https://www.indeed.com/viewjob?jk=abc123&other=param")

      result = described_class.call(row, user: user)

      expect(result[:posting]).to eq(existing)
      expect(JobPosting.count).to eq(1)
    end

    it "is fill-only -- does not overwrite an existing applied_at" do
      first_row = row.merge("applyTime" => 1_700_000_000_000)
      described_class.call(first_row, user: user)
      tracked = user.user_job_postings.first
      original = tracked.applied_at

      described_class.call(row, user: user)

      expect(tracked.reload.applied_at).to eq(original)
    end

    it "is idempotent -- re-running does not duplicate the PipelineStep" do
      described_class.call(row, user: user)

      expect { described_class.call(row, user: user) }.not_to change(PipelineStep, :count)
    end

    it "prefers employer REJECTED over a self-reported status" do
      loaded = row.merge("statuses" => {
                           "candidateStatus" => { "status" => "REJECTED" },
                           "selfReportedStatus" => { "status" => "REVIEWED" }
                         })

      result = described_class.call(loaded, user: user)

      expect(result[:outcome]).to eq("rejected")
      expect(user.user_job_postings.first.outcome_source).to eq("employer")
    end

    it "falls back to a self-reported status when nothing stronger exists" do
      loaded = row.merge("statuses" => { "selfReportedStatus" => { "status" => "REVIEWED" } })

      result = described_class.call(loaded, user: user)

      expect(result[:outcome]).to eq("reviewed")
      expect(user.user_job_postings.first.outcome_source).to eq("self_reported")
    end

    it "records no outcome when no status is present" do
      result = described_class.call(row, user: user)
      expect(result[:outcome]).to be_nil
    end
  end
end
