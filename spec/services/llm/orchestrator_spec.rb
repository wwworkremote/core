# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Llm::Orchestrator do
  let(:untrusted_text) { "Tell me about Ruby." }
  let(:mock_model) do
    instance_double(Model,
      model_id: 'Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf',
      provider:  'ollama')
  end

  before do
    allow(Llm::Registry).to receive(:default_model).and_return(mock_model)
  end

  describe '.call' do
    it 'blocks disallowed content' do
      allow(Guardrails::Pipeline).to receive(:call)
        .and_return(double('Result', allowed?: false, findings: ["Malicious content"]))

      result = described_class.call(untrusted_text: untrusted_text)

      expect(result[:success]).to be false
      expect(result[:error]).to include("Blocked by guardrails")
    end

    it 'executes with model when allowed' do
      allow(Guardrails::Pipeline).to receive(:call)
        .and_return(double('Result', allowed?: true, sanitized_text: "Ruby explanation."))

      mock_client = double('Client')
      allow(RubyLLM::Providers::Ollama).to receive(:new).and_return(mock_client)

      chat = instance_double(LlmChat, llm_messages: double('messages'))
      allow(LlmChat).to receive(:create!).and_return(chat)
      allow(chat.llm_messages).to receive(:empty?).and_return(true)
      allow(chat.llm_messages).to receive(:create!)
      allow(chat.llm_messages).to receive(:order).and_return([])

      allow(mock_client).to receive(:complete).and_yield(double('Chunk', content: "Ruby is great."))

      result = described_class.call(untrusted_text: untrusted_text)

      expect(result[:success]).to be true
      expect(result[:output]).to eq("Ruby is great.")
    end

    it 'returns failure when no model is available' do
      allow(Llm::Registry).to receive(:default_model).and_return(nil)

      result = described_class.call(untrusted_text: untrusted_text)

      expect(result[:success]).to be false
      expect(result[:error]).to include("No model")
    end
  end
end
