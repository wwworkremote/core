# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::InterviewPrepGenerator::SpokenRewriter do
  describe ".call" do
    it "sends the human pack to the orchestrator as the text to rewrite" do
      captured = nil
      allow(LLM::Orchestrator).to receive(:call) { |args| captured = args; { success: true, output: "spoken" } }

      described_class.call("## The Setup\nYou are a Sr. Engineer.")

      expect(captured[:untrusted_text]).to eq("## The Setup\nYou are a Sr. Engineer.")
      expect(captured[:task_instructions]).to include("Spell out abbreviations")
      expect(captured[:task_instructions]).to include("YAML frontmatter block")
    end

    it "returns the rewritten text on success" do
      allow(LLM::Orchestrator).to receive(:call).and_return(success: true, output: "--- \ntitle: x\n---\nbody")

      expect(described_class.call("in")).to eq("--- \ntitle: x\n---\nbody")
    end

    it "returns nil when the rewrite fails" do
      allow(LLM::Orchestrator).to receive(:call).and_return(success: false, error: "boom")

      expect(described_class.call("in")).to be_nil
    end
  end
end
