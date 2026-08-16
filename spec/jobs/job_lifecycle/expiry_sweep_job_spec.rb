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

  it "preserves a favorited posting even when stale" do
    posting = create(:job_posting, status: "favorited", published_at: 1.year.ago)

    described_class.perform_now

    expect(posting.reload.status).to eq("favorited")
  end

  it "does not touch an already-purged posting" do
    posting = create(:job_posting, status: "none", published_at: 1.year.ago)
    posting.purge!

    described_class.perform_now

    expect(posting.reload.status).to eq("purged")
  end
end
