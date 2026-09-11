# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobLifecycle::ExpirySweepJob do
  it "expires a stale posting past the 72-hour window" do
    posting = create(:job_posting, status: "none", published_at: 73.hours.ago)

    described_class.perform_now

    expect(posting.reload.status).to eq("expired")
  end

  it "leaves a fresh posting untouched" do
    posting = create(:job_posting, status: "none", published_at: 1.hour.ago)

    described_class.perform_now

    expect(posting.reload.status).to eq("none")
  end

  it "preserves a posting with active pipeline involvement even when stale" do
    # Pipeline stage lives on UserJobPosting as of TASK-82 phase 3 -- a
    # JobPosting itself has no "favorited" status anymore.
    posting = create(:job_posting, status: "none", published_at: 1.year.ago)
    create(:user_job_posting, job_posting: posting, status: "favorited")

    described_class.perform_now

    expect(posting.reload.status).to eq("none")
  end

  it "preserves a posting with an offer recorded even when stale" do
    posting = create(:job_posting, status: "none", published_at: 1.year.ago)
    create(:user_job_posting, job_posting: posting, status: "applied", outcome: "offered")

    described_class.perform_now

    expect(posting.reload.status).to eq("none")
  end

  it "expires a stale posting with no pipeline involvement even if once tracked and cleared" do
    posting = create(:job_posting, status: "none", published_at: 1.year.ago)
    create(:user_job_posting, job_posting: posting, status: "none")

    described_class.perform_now

    expect(posting.reload.status).to eq("expired")
  end

  it "does not touch an already-purged posting" do
    posting = create(:job_posting, status: "none", published_at: 1.year.ago)
    posting.purge!

    described_class.perform_now

    expect(posting.reload.status).to eq("purged")
  end
end
