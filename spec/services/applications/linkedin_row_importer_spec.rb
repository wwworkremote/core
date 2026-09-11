# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::LinkedinRowImporter do
  let(:user) { create(:user) }
  let(:row) do
    { id: "12345678", title: "Staff Engineer", company: "Acme", location: "Remote",
      note: "Applied 3mo ago", closed: false }
  end

  describe "#call" do
    it "records an applied stage as an actual apply" do
      result = described_class.call(row, user: user, stage: "applied")

      tracked = user.user_job_postings.find_by(job_posting: result[:posting])
      expect(tracked.status).to eq("applied")
    end

    it "records clicked_apply as a favorite, never an apply -- LinkedIn can't confirm it finished" do
      result = described_class.call(row, user: user, stage: "clicked_apply")

      tracked = user.user_job_postings.find_by(job_posting: result[:posting])
      expect(tracked.status).to eq("favorited")
    end

    it "records saved as a favorite" do
      result = described_class.call(row, user: user, stage: "saved")

      tracked = user.user_job_postings.find_by(job_posting: result[:posting])
      expect(tracked.status).to eq("favorited")
    end

    it "matches an existing posting via the /jobs/view/ native id fragment" do
      existing = create(:job_posting, target_url: "https://www.linkedin.com/jobs/view/12345678/")

      result = described_class.call(row, user: user, stage: "applied")

      expect(result[:posting]).to eq(existing)
      expect(JobPosting.count).to eq(1)
    end

    it "sets an approximate applied_at from the relative age when the row is new" do
      result = described_class.call(row, user: user, stage: "applied")

      tracked = user.user_job_postings.find_by(job_posting: result[:posting])
      expect(tracked.applied_at).to be_within(1.day).of(3.months.ago)
    end

    it "does not overwrite a real applied_at another source already recorded (fill-only)" do
      posting = create(:job_posting, target_url: "https://www.linkedin.com/jobs/view/12345678/")
      exact = Time.zone.parse("2026-08-01T00:00:00Z")
      user.user_job_postings.create!(job_posting: posting, status: "applied", applied_at: exact)

      described_class.call(row, user: user, stage: "applied")

      expect(user.user_job_postings.find_by(job_posting: posting).applied_at).to eq(exact)
    end

    it "appends an approximate-date note, once, even across re-runs" do
      described_class.call(row, user: user, stage: "applied")
      tracked = user.user_job_postings.first
      expect(tracked.notes).to include("Applied 3mo ago")

      expect { described_class.call(row, user: user, stage: "applied") }.not_to(change { tracked.reload.notes })
    end

    it "records a closed outcome only when LinkedIn says the listing closed" do
      result = described_class.call(row.merge(closed: true), user: user, stage: "applied")

      expect(result[:outcome]).to eq("closed")
      expect(user.user_job_postings.first.outcome_source).to eq("self_reported")
    end

    it "never overwrites a stronger outcome another source already recorded" do
      posting = create(:job_posting, target_url: "https://www.linkedin.com/jobs/view/12345678/")
      tracked = user.user_job_postings.create!(job_posting: posting, status: "applied", outcome: "rejected",
                                               outcome_source: "employer")

      described_class.call(row.merge(closed: true), user: user, stage: "applied")

      expect(tracked.reload.outcome).to eq("rejected")
    end

    it "is idempotent -- re-running does not duplicate the PipelineStep" do
      described_class.call(row, user: user, stage: "applied")

      expect {
        described_class.call(row, user: user, stage: "applied")
      }.not_to change(PipelineStep, :count)
    end
  end
end
