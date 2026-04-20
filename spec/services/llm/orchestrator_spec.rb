# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Llm::Orchestrator do
  let(:untrusted_text) { "Tell me about Ruby." }

  describe '.call' do
    it 'blocks disallowed content' do
      expect(Guardrails::Pipeline).to receive(:call).and_return(double('Result', allowed?: false, findings: ["Malicious content"]))
      
      result = described_class.call(untrusted_text: untrusted_text)
      
      expect(result[:success]).to be false
      expect(result[:error]).to include("Blocked by guardrails")
    end

    it 'executes with model when allowed' do
      expect(Guardrails::Pipeline).to receive(:call).and_return(double('Result', allowed?: true, sanitized_text: "Ruby explanation."))
      
      mock_client = double('Client')
      expect(RubyLLM::Providers::Ollama).to receive(:new).and_return(mock_client)
      expect(mock_client).to receive(:complete).and_return(double('Response', content: "Ruby is great."))

      result = described_class.call(untrusted_text: untrusted_text)
      
      expect(result[:success]).to be true
    end
  end
end
