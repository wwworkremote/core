# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::Orchestrator do
  let(:untrusted_text) { "Normalize this job: Ruby dev at TestCorp." }
  let(:model_id) { "llama3.2:latest" }
  let!(:model) { create(:model, model_id: model_id, provider: "ollama") }

  before do
    allow(LLM::Registry).to receive(:default_model).and_return(model)
  end

  describe ".call" do
    it "executes the full chain including guardrails and real HTTP communication" do
      # Realistic SSE (Server-Sent Events) response body
      sse_body = <<~SSE
        data: {"choices":[{"delta":{"content":"{\\n  \\\"title\\\": \\\"Senior Ruby Engineer\\\",\\n  \\\"company\\\": \\\"TestCorp\\\"\\n}"}}]}

        data: [DONE]
      SSE

      stub_request(:post, "http://localhost:8080/v1/chat/completions")
        .to_return(status: 200, body: sse_body, headers: { "Content-Type" => "text/event-stream" })

      result = described_class.call(
        untrusted_text: untrusted_text,
        system_rules: "You are a helpful assistant.",
        metadata: {}
      )

      expect(result[:success]).to be true
      expect(result[:output]).to include("Senior Ruby Engineer")
      expect(LLMChat.count).to eq(1)
    end

    it "gracefully handles LLM connection failures" do
      stub_request(:post, %r{localhost:8080/v1/chat/completions})
        .to_raise(Faraday::ConnectionFailed.new("Connection refused"))

      result = described_class.call(untrusted_text: untrusted_text, metadata: {})

      expect(result[:success]).to be false
      expect(result[:error]).to include("Model execution failed")
    end

    it "handles malformed or empty output from the provider" do
      stub_request(:post, %r{localhost:8080/v1/chat/completions})
        .to_return(status: 200, body: "", headers: {})

      result = described_class.call(untrusted_text: untrusted_text, metadata: {})

      expect(result[:success]).to be true
      expect(result[:output]).to eq("")
    end
  end
end
