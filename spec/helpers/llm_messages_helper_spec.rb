# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLMMessagesHelper, type: :helper do
  describe "#partial_for" do
    it "returns the default partial if specific one doesn't exist" do
      # lookup_context is available in helper specs
      expect(helper.send(:partial_for, prefix: "llm_messages/tool_calls", name: "ghost_tool")).to eq("llm_messages/tool_calls/default")
    end

    it "returns specific partial if it exists" do
      # Stub lookup_context to simulate existing partial
      allow(helper.lookup_context).to receive(:exists?).with("specific_tool", ["llm_messages/tool_calls"], true).and_return(true)
      
      expect(helper.send(:partial_for, prefix: "llm_messages/tool_calls", name: "specific-tool")).to eq("llm_messages/tool_calls/specific_tool")
    end
  end
end
