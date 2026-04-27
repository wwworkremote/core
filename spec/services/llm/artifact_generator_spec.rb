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
      create(:work_experience, career_profile: profile, title: "Dev", summary: "Ruby stuff", impact: "Scale", start_date: 1.year.ago, company_name: "Tech Corp")
      create(:work_experience, career_profile: profile, title: "Lead", summary: "Managing", impact: "Team", start_date: Time.current, company_name: "Tech Corp")
      
      expect(LLM::Orchestrator).to receive(:call) do |args|
        expect(args[:untrusted_text]).to include("Lead at Tech Corp") # Most recent first
        expect(args[:untrusted_text]).to include("Dev at Tech Corp")
        { success: true, output: "Dear Hiring Manager..." }
      end

      result = described_class.call(user, job)
      expect(result[:success]).to be true
    end

    it "handles missing skills and goals in profile gracefully" do
      profile.update!(skills: nil, goals: nil)
      create(:work_experience, career_profile: profile, title: "Dev", summary: "A", impact: "B")
      
      expect(LLM::Orchestrator).to receive(:call).and_return({ success: true, output: "Draft" })
      
      result = described_class.call(user, job)
      expect(result[:success]).to be true
    end

    it "handles LLM failures" do
      create(:work_experience, career_profile: profile, title: "Dev", summary: "A", impact: "B")
      allow(LLM::Orchestrator).to receive(:call).and_return({ success: false, error: "Timed out" })
      
      result = described_class.call(user, job)
      expect(result[:success]).to be false
      expect(result[:error]).to eq("Timed out")
    end
  end
end
