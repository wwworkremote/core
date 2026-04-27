# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::ArtifactGenerator do
  let(:user) { create(:user) }
  let!(:profile) { create(:career_profile, user: user) }
  let(:job) { create(:job_posting) }
  let(:generator) { described_class.new(user, job) }

  describe ".call" do
    it "returns error if no work experiences" do
      result = described_class.call(user, job)
      expect(result[:success]).to be false
      expect(result[:error]).to include("Profile incomplete")
    end

    it "generates and attaches cover letter when profile is complete" do
      create(:work_experience, career_profile: profile, title: "Dev", summary: "Ruby stuff", impact: "Scale")
      
      expect(LLM::Orchestrator).to receive(:call).and_return({ success: true, output: "Dear Hiring Manager..." })

      result = described_class.call(user, job)
      expect(result[:success]).to be true
      expect(result[:output]).to eq("Dear Hiring Manager...")
      
      user_job = user.user_job_postings.find_by(job_posting: job)
      expect(user_job.notes).to include("[GENERATED_COVER_LETTER]")
      expect(user_job.notes).to include("Dear Hiring Manager...")
    end
  end
end
