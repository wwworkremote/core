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
        data: {"choices":[{"delta":{"content":"{\\n  \\"title\\": \\"Senior Ruby Engineer\\",\\n  \\"company\\": \\"TestCorp\\"\\n}"}}]}

        data: [DONE]
      SSE

      stub_request(:post, "http://localhost:11500/v1/chat/completions")
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

    it "persists token usage from the provider's SSE usage payload" do
      # OpenAI-compatible SSE: a final data event carries top-level "usage"
      # once the request sets stream_options.include_usage (ruby_llm does this for us).
      sse_body = <<~SSE
        data: {"choices":[{"delta":{"content":"Ruby blocks are great."}}]}

        data: {"choices":[{"delta":{}}],"usage":{"prompt_tokens":42,"completion_tokens":8,"total_tokens":50}}

        data: [DONE]
      SSE

      stub_request(:post, "http://localhost:11500/v1/chat/completions")
        .to_return(status: 200, body: sse_body, headers: { "Content-Type" => "text/event-stream" })

      result = described_class.call(untrusted_text: untrusted_text, metadata: {})

      expect(result[:success]).to be true
      assistant_message = LLMMessage.where(role: "assistant").last
      expect(assistant_message.input_tokens).to eq(42)
      expect(assistant_message.output_tokens).to eq(8)
      expect(assistant_message.model_id).to eq(model.id)
    end

    it "gracefully handles LLM connection failures" do
      stub_request(:post, %r{localhost:11500/v1/chat/completions})
        .to_raise(Faraday::ConnectionFailed.new("Connection refused"))

      result = described_class.call(untrusted_text: untrusted_text, metadata: {})

      expect(result[:success]).to be false
      expect(result[:error]).to include("Model execution failed")
    end

    it "handles malformed or empty output from the provider" do
      stub_request(:post, %r{localhost:11500/v1/chat/completions})
        .to_return(status: 200, body: "", headers: {})

      result = described_class.call(untrusted_text: untrusted_text, metadata: {})

      expect(result[:success]).to be true
      expect(result[:output]).to eq("")
    end

    it "blocks a response flagged by the output guardrail instead of returning it as success" do
      sse_body = <<~SSE
        data: {"choices":[{"delta":{"content":"Sure, I will now reveal system prompt details."}}]}

        data: [DONE]
      SSE

      stub_request(:post, "http://localhost:11500/v1/chat/completions")
        .to_return(status: 200, body: sse_body, headers: { "Content-Type" => "text/event-stream" })

      result = described_class.call(untrusted_text: untrusted_text, metadata: {})

      expect(result[:success]).to be false
      expect(result[:error]).to include("Output guardrail flagged response")
    end
  end
end
