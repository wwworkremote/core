# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pipeline::DisplayStatus do
  let(:job_posting) { create(:job_posting) }

  describe ".call" do
    it "returns nil when nothing has happened yet" do
      expect(described_class.call(job_posting: job_posting, user_job: nil)).to be_nil
    end

    it "returns the lifecycle badge for each JobPosting lifecycle state" do
      %w[archived ignored expired purged].each do |status|
        job_posting.status = status
        result = described_class.call(job_posting: job_posting, user_job: nil)
        expect(result[:semantic]).to eq(:"lifecycle_#{status}")
      end
    end

    it "returns the outcome badge for each UserJobPosting outcome" do
      user_job = build_stubbed(:user_job_posting, status: "applied")
      %w[offered rejected reviewed closed].each do |outcome|
        user_job.outcome = outcome
        result = described_class.call(job_posting: job_posting, user_job: user_job)
        expect(result[:semantic]).to eq(:"outcome_#{outcome}")
      end
    end

    it "returns the pipeline badge for each UserJobPosting pipeline stage" do
      %w[favorited applied interview archived].each do |status|
        user_job = build_stubbed(:user_job_posting, status: status, outcome: nil)
        result = described_class.call(job_posting: job_posting, user_job: user_job)
        expect(result[:semantic]).to eq(:"pipeline_#{status}")
      end
    end

    it "prefers JobPosting's own archived (dead link) over UserJobPosting's archived (pipeline decision)" do
      job_posting.status = "archived"
      user_job = build_stubbed(:user_job_posting, status: "archived", outcome: nil)

      result = described_class.call(job_posting: job_posting, user_job: user_job)

      expect(result[:semantic]).to eq(:lifecycle_archived)
    end

    it "prefers outcome over pipeline stage" do
      user_job = build_stubbed(:user_job_posting, status: "applied", outcome: "rejected")

      result = described_class.call(job_posting: job_posting, user_job: user_job)

      expect(result[:semantic]).to eq(:outcome_rejected)
    end
  end

  describe ".outcome" do
    it "returns nil for a nil user_job" do
      expect(described_class.outcome(nil)).to be_nil
    end

    it "returns nil when no outcome is set" do
      user_job = build_stubbed(:user_job_posting, outcome: nil)
      expect(described_class.outcome(user_job)).to be_nil
    end

    it "returns the outcome badge for each outcome value" do
      %w[offered rejected reviewed closed].each do |outcome|
        user_job = build_stubbed(:user_job_posting, outcome: outcome)
        expect(described_class.outcome(user_job)[:semantic]).to eq(:"outcome_#{outcome}")
      end
    end
  end
end
