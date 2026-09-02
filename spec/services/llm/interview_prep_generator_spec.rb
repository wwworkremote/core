# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::InterviewPrepGenerator do
  let(:user) { create(:user) }
  let!(:profile) { create(:career_profile, user: user) }
  let(:job) { create(:job_posting) }

  describe ".call" do
    it "returns an error when the profile has no work experiences" do
      result = described_class.call(user, job)

      expect(result[:success]).to be false
      expect(result[:error]).to include("Profile incomplete")
    end

    it "aborts for an expired job posting unless forced" do
      create(:work_experience, career_profile: profile, title: "Dev", summary: "A", impact: "B")
      job.expire!

      result = described_class.call(user, job)

      expect(result[:success]).to be false
      expect(result[:error]).to include("expired/stale")
    end

    it "generates for an expired posting when forced" do
      create(:work_experience, career_profile: profile, title: "Dev", summary: "A", impact: "B")
      job.expire!
      allow(LLM::Orchestrator).to receive(:call).and_return(success: true, output: "# Prep")

      result = described_class.call(user, job, force: true)

      expect(result[:success]).to be true
    end

    it "stores the pack and a generated-at timestamp on the user job posting" do
      create(:work_experience, career_profile: profile, title: "Dev", summary: "A", impact: "B")
      allow(LLM::Orchestrator).to receive(:call).and_return(success: true, output: "# Prep pack\nbody")

      described_class.call(user, job)

      user_job = user.user_job_postings.find_by(job_posting: job)
      expect(user_job.interview_prep_pack).to eq("# Prep pack\nbody")
      expect(user_job.interview_prep_pack_generated_at).to be_within(5.seconds).of(Time.current)
    end

    it "does not touch personal notes on an existing record" do
      create(:work_experience, career_profile: profile, title: "Dev", summary: "A", impact: "B")
      user_job = create(:user_job_posting, user: user, job_posting: job, notes: "my own notes")
      allow(LLM::Orchestrator).to receive(:call).and_return(success: true, output: "# Prep")

      described_class.call(user, job)

      expect(user_job.reload.notes).to eq("my own notes")
    end

    it "passes the LLM failure through" do
      create(:work_experience, career_profile: profile, title: "Dev", summary: "A", impact: "B")
      allow(LLM::Orchestrator).to receive(:call).and_return(success: false, error: "Timed out")

      result = described_class.call(user, job)

      expect(result[:success]).to be false
      expect(result[:error]).to eq("Timed out")
    end
  end
end
