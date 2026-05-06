# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::CompanyAuditor do
  let(:company) { create(:company, name: "TestCorp") }
  let(:raw_feedback) { "Great pay but lots of overtime and micromanagement." }
  let(:auditor) { described_class.new(company, raw_feedback) }
  let!(:model) { create(:model, model_id: "llama3.2:latest", provider: "ollama") }

  before do
    allow(LLM::Registry).to receive(:default_model).and_return(model)
  end

  describe "#call" do
    it "updates the company with LLM audit data" do
      llm_json = {
        disposition: "Toxic",
        sentiment_score: 0.2,
        toxic_culture_flag: true,
        summary: "High burnout risk detected.",
        top_pros: ["Good pay"],
        top_cons: %w[Micromanagement Overtime]
      }.to_json

      # Realistic SSE format for RubyLLM
      sse_body = "data: {\"choices\":[{\"delta\":{\"content\":#{llm_json.inspect}}}]}\n\ndata: [DONE]\n"

      stub_request(:post, "http://localhost:8080/v1/chat/completions")
        .to_return(status: 200, body: sse_body, headers: { "Content-Type" => "text/event-stream" })

      result = auditor.call

      expect(result[:success]).to be true
      company.reload
      expect(company.disposition).to eq("Toxic")
      expect(company.sentiment_score).to eq(0.2)
      expect(company.toxic_culture_flag).to be true
      expect(company.glassdoor_data["reputation_audit"]["summary"]).to eq("High burnout risk detected.")
    end

    it "handles LLM failures gracefully" do
      stub_request(:post, "http://localhost:8080/v1/chat/completions")
        .to_return(status: 500, body: "Internal Server Error")

      result = auditor.call
      expect(result[:success]).to be false
      expect(result[:error]).to include("Model execution failed")
    end

    it "returns error if raw feedback is blank" do
      result = described_class.call(company, "")
      expect(result[:success]).to be false
      expect(result[:error]).to eq("No feedback provided.")
    end
  end
end
