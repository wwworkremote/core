# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::Categorizer do
  let(:job_posting) { create(:job_posting, body: "We need a Ruby on Rails expert.", data: {}) }
  let(:categorizer) { described_class.new(job_posting) }
  let(:model_id) { LLM::Registry.default_model_id }
  let!(:model) { create(:model, model_id: model_id, provider: "ollama") }

  before do
    RubyLLM.config.default_model = model_id
    allow(LLM::Registry).to receive(:default_model).and_return(model)
  end

  describe "#call" do
    it "updates the job posting with data from the LLM via real HTTP simulation" do
      # Realistic JSON response from the LLM
      llm_json = {
        category: "Software Engineering",
        tags: %w[ruby rails],
        is_remote: true,
        remote_nuance: "Strictly remote",
        salary_min: 100_000,
        salary_max: 150_000,
        currency: "USD"
      }.to_json

      # Realistic SSE format for RubyLLM's streaming expectation
      sse_body = "data: {\"choices\":[{\"delta\":{\"content\":#{llm_json.inspect}}}]}\n\ndata: [DONE]\n"

      stub_request(:post, "http://localhost:11500/v1/chat/completions")
        .to_return(status: 200, body: sse_body, headers: { "Content-Type" => "text/event-stream" })

      categorizer.call

      job_posting.reload
      expect(job_posting.data["ai_category"]).to eq("Software Engineering")
      expect(job_posting.tags).to contain_exactly("ruby", "rails")
      expect(job_posting.data["is_remote"]).to be true
    end

    it "handles malformed JSON from the LLM gracefully" do
      # LLM returns some chatter before/after valid JSON or just broken stuff
      bad_body = "data: {\"choices\":[{\"delta\":{\"content\":\"I am thinking... here is your data: { broken json\"}}]}\n\ndata: [DONE]\n"

      stub_request(:post, "http://localhost:11500/v1/chat/completions")
        .to_return(status: 200, body: bad_body, headers: { "Content-Type" => "text/event-stream" })

      expect {
        categorizer.call
      }.not_to raise_error

      job_posting.reload
      expect(job_posting.data["ai_category"]).to be_nil
    end

    it "handles LLM failures gracefully" do
      stub_request(:post, "http://localhost:11500/v1/chat/completions")
        .to_return(status: 500, body: "Internal Server Error")

      # Use allow and check later or use a more specific match
      expect(Rails.logger).to receive(:error).with(include("execution failed"))
      expect(Rails.logger).to receive(:error).with(include("Agent failed for Job"))

      categorizer.call
    end
  end
end
