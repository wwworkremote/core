# frozen_string_literal: true

require "rails_helper"

RSpec.describe Leads::CaptureService do
  let(:user) { create(:user) }
  let(:lead) { create(:lead, provider: "linkedin") }
  let(:target_url) { "https://example.com/jobs/shared-apply-link" }
  let(:params) do
    ActionController::Parameters.new(
      title: "Senior Engineer",
      location: "Remote",
      target_url: target_url,
      body: "Job body",
      company: { name: "Acme Corp" }
    ).permit(:title, :location, :target_url, :body, :company_id, company: [:name], data: {})
  end

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  describe ".call" do
    it "creates a new JobPosting and links the lead" do
      result = described_class.call(lead: lead, params: params, user: user)

      expect(result[:success]).to be true
      expect(lead.reload.job_posting).to eq(result[:job_posting])
      expect(lead.status).to eq("promoted")
    end

    it "enqueues the downstream analysis and AI pipeline" do
      expect { described_class.call(lead: lead, params: params, user: user) }
        .to have_enqueued_job(JobBoards::AnalysisJob)
        .and have_enqueued_job(LLM::ProfileMatchJob)
        .and have_enqueued_job(JobBoards::StrategyJob)
    end

    it "updates the same JobPosting in place on a genuine re-promote of the same lead" do
      first = described_class.call(lead: lead, params: params, user: user)
      updated_params = ActionController::Parameters.new(params.to_unsafe_h.merge(title: "Staff Engineer"))
                                                   .permit(:title, :location, :target_url, :body, :company_id,
                                                           company: [:name], data: {})

      second = described_class.call(lead: lead, params: updated_params, user: user)

      expect(second[:job_posting].id).to eq(first[:job_posting].id)
      expect(second[:job_posting].title).to eq("Staff Engineer")
    end

    context "when the target_url collides with a JobPosting owned by a different lead" do
      let!(:other_job_posting) do
        create(:job_posting, target_url: target_url,
                             signature: Digest::SHA256.hexdigest(target_url),
                             title: "Unrelated Existing Posting", company_name: "Someone Else Inc")
      end

      it "does not mutate the unrelated JobPosting and creates a distinct new one" do
        result = described_class.call(lead: lead, params: params, user: user)

        expect(result[:success]).to be true
        expect(result[:job_posting].id).not_to eq(other_job_posting.id)
        expect(other_job_posting.reload.title).to eq("Unrelated Existing Posting")
        expect(result[:job_posting].title).to eq("Senior Engineer")
      end
    end
  end
end
