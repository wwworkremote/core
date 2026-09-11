# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::GreenhouseRowImporter do
  let(:user) { create(:user) }
  let(:app) do
    { "id" => "gh-1", "job_post_id" => "12345", "job_post_url" => "https://job-boards.greenhouse.io/acme/jobs/12345",
      "job_title" => "Staff Engineer", "company_name" => "Acme", "locations" => "Remote",
      "applied_at" => "2026-08-01T12:00:00Z", "currentStage" => nil, "inactive" => false }
  end

  describe "#call" do
    it "creates a JobPosting and an applied UserJobPosting" do
      result = described_class.call(app, user: user)

      expect(result[:posting]).to be_persisted
      expect(result[:posting].title).to eq("Staff Engineer")
      expect(result[:posting].company_name).to eq("Acme")
      tracked = user.user_job_postings.find_by(job_posting: result[:posting])
      expect(tracked.status).to eq("applied")
      expect(tracked.applied_at).to eq(Time.zone.parse("2026-08-01T12:00:00Z"))
    end

    it "matches an existing posting instead of creating a duplicate" do
      existing = create(:job_posting, target_url: "https://job-boards.greenhouse.io/acme/jobs/12345")

      result = described_class.call(app, user: user)

      expect(result[:posting]).to eq(existing)
      expect(JobPosting.count).to eq(1)
    end

    it "backfills a blank company_name on an existing match" do
      existing = create(:job_posting, company: nil, target_url: "https://job-boards.greenhouse.io/acme/jobs/12345")
      expect(existing.company_name).to be_blank

      described_class.call(app, user: user)

      expect(existing.reload.company_name).to eq("Acme")
    end

    it "is idempotent -- re-running does not duplicate the PipelineStep or applied_at" do
      described_class.call(app, user: user)
      tracked = user.user_job_postings.first
      first_applied_at = tracked.applied_at

      expect { described_class.call(app, user: user) }.not_to change(PipelineStep, :count)
      expect(tracked.reload.applied_at).to eq(first_applied_at)
    end

    it "overwrites an existing applied_at, since Greenhouse's date is authoritative" do
      described_class.call(app.merge("applied_at" => "2026-01-01T00:00:00Z"), user: user)

      described_class.call(app, user: user)

      tracked = user.user_job_postings.first
      expect(tracked.applied_at).to eq(Time.zone.parse("2026-08-01T12:00:00Z"))
    end

    it "records a rejected outcome when currentStage mentions reject" do
      result = described_class.call(app.merge("currentStage" => "Rejected"), user: user)

      expect(result[:outcome]).to eq("rejected")
      expect(user.user_job_postings.first.outcome_source).to eq("employer")
    end

    it "records a closed outcome when the application is inactive with no reject signal" do
      result = described_class.call(app.merge("inactive" => true), user: user)

      expect(result[:outcome]).to eq("closed")
    end

    it "records no outcome for an active application" do
      result = described_class.call(app, user: user)
      expect(result[:outcome]).to be_nil
    end
  end
end
