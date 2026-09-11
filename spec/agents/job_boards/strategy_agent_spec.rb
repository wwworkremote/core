# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::StrategyAgent do
  let(:agent) { described_class.new(chat: Object.new) }
  let(:company) { create(:company, name: "Acme Corp") }
  let(:job_posting) { create(:job_posting, title: "Staff Engineer", company_id: company.id, body: "Build things.") }
  let(:user_job_posting) { create(:user_job_posting, job_posting: job_posting, match_analysis: "Strong fit.") }

  describe "#call" do
    it "persists the parsed strategy fields onto the UserJobPosting on success" do
      output = {
        "resume_track" => "backend", "talking_points" => ["Scaled a payments system"],
        "company_research_summary" => "Series B fintech.", "key_risks" => ["Unclear roadmap"]
      }.to_json
      allow(LLM::Orchestrator).to receive(:call).and_return({ success: true, output: output })

      result = agent.call(job_posting, user_job_posting)

      expect(result[:success]).to be true
      strategy = user_job_posting.reload.strategy
      expect(strategy["resume_track"]).to eq("backend")
      expect(strategy["talking_points"]).to eq(["Scaled a payments system"])
      expect(strategy["generated_at"]).to be_present
    end

    it "does not touch the UserJobPosting when the LLM call fails" do
      allow(LLM::Orchestrator).to receive(:call).and_return({ success: false, output: nil })

      agent.call(job_posting, user_job_posting)

      expect(user_job_posting.reload.strategy).to eq({})
    end

    it "leaves the strategy untouched when the LLM returns unparseable output" do
      allow(LLM::Orchestrator).to receive(:call).and_return({ success: true, output: "not json" })

      agent.call(job_posting, user_job_posting)

      expect(user_job_posting.reload.strategy.keys).to eq(["generated_at"])
    end
  end

  describe "#render_instructions" do
    it "falls back to the default instructions template when no admin prompt is active" do
      expect(agent.render_instructions).to include("resume_track")
    end

    it "uses the admin-edited prompt body when one is active for this key" do
      PipelinePrompt.create!(key: "job_boards_strategy", name: "Custom", stage: "strategy", body: "Custom prompt body")

      expect(agent.render_instructions).to eq("Custom prompt body")
    end
  end
end
