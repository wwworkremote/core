# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::InterviewPrepGenerator do
  let(:user) { create(:user) }
  let!(:profile) { create(:career_profile, user: user) }
  let(:job) { create(:job_posting) }

  before { allow(LLM::InterviewPrepGenerator::SpokenRewriter).to receive(:call).and_return("--- \ntitle: x\n---\nspoken") }

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

    it "stores a read-aloud version rewritten from the human pack" do
      create(:work_experience, career_profile: profile, title: "Dev", summary: "A", impact: "B")
      allow(LLM::Orchestrator).to receive(:call).and_return(success: true, output: "# Human pack")
      spoken = "--- \ntitle: y\n---\nspoken body"
      allow(LLM::InterviewPrepGenerator::SpokenRewriter).to receive(:call).with("# Human pack").and_return(spoken)

      described_class.call(user, job)

      user_job = user.user_job_postings.find_by(job_posting: job)
      expect(user_job.interview_prep_pack_spoken).to eq(spoken)
    end

    it "skips the read-aloud version when spoken: false" do
      create(:work_experience, career_profile: profile, title: "Dev", summary: "A", impact: "B")
      allow(LLM::Orchestrator).to receive(:call).and_return(success: true, output: "# Human pack")

      described_class.call(user, job, spoken: false)

      expect(LLM::InterviewPrepGenerator::SpokenRewriter).not_to have_received(:call)
      expect(user.user_job_postings.find_by(job_posting: job).interview_prep_pack_spoken).to be_nil
    end

    it "keeps the human pack when the read-aloud rewrite fails" do
      create(:work_experience, career_profile: profile, title: "Dev", summary: "A", impact: "B")
      allow(LLM::Orchestrator).to receive(:call).and_return(success: true, output: "# Human pack")
      allow(LLM::InterviewPrepGenerator::SpokenRewriter).to receive(:call).and_return(nil)

      result = described_class.call(user, job)

      expect(result[:success]).to be true
      user_job = user.user_job_postings.find_by(job_posting: job)
      expect(user_job.interview_prep_pack).to eq("# Human pack")
      expect(user_job.interview_prep_pack_spoken).to be_nil
    end

    it "does not touch personal notes on an existing record" do
      create(:work_experience, career_profile: profile, title: "Dev", summary: "A", impact: "B")
      user_job = create(:user_job_posting, user: user, job_posting: job, notes: "my own notes")
      allow(LLM::Orchestrator).to receive(:call).and_return(success: true, output: "# Prep")

      described_class.call(user, job)

      expect(user_job.reload.notes).to eq("my own notes")
    end

    it "routes the posting body through the orchestrator as untrusted text" do
      create(:work_experience, career_profile: profile, title: "Dev", summary: "A", impact: "B")
      job.update!(body: "SCRAPED POSTING BODY")
      captured = nil
      allow(LLM::Orchestrator).to receive(:call) { |args| captured = args; { success: true, output: "x" } }

      described_class.call(user, job)

      expect(captured[:untrusted_text]).to include("SCRAPED POSTING BODY")
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
