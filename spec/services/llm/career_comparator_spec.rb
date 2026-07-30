# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::CareerComparator do
  let(:user) { create(:user) }
  let(:jobs) { create_list(:job_posting, 3) }

  before { create(:career_profile, user: user, skills: "Ruby", goals: "Remote") }

  describe ".call" do
    it "delegates to LLM::Orchestrator for comparison" do
      allow(LLM::Orchestrator).to receive(:call).and_return({ success: true, output: "Ranking: 1. Job A" })

      result = described_class.call(user, jobs)

      expect(result[:success]).to be true
      expect(result[:output]).to eq("Ranking: 1. Job A")
      expect(LLM::Orchestrator).to have_received(:call).with(
        hash_including(untrusted_text: /Perform a comparative semantic analysis/)
      )
    end

    it "returns error if fewer than 2 jobs provided" do
      result = described_class.call(user, [jobs.first])
      expect(result[:success]).to be false
      expect(result[:error]).to include("at least 2 jobs")
    end
  end
end
