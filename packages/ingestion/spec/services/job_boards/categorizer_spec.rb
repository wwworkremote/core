# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::Categorizer do
  let(:job_posting) { create(:job_posting, body: "We need a Ruby on Rails expert.", data: {}) }
  let(:categorizer) { described_class.new(job_posting) }
  let(:model_id) { LLM::Registry.default_model_id }
  # find_or_create, not create: rails_helper's before(:suite) already syncs
  # LLM::Registry's models (including this default one) once for the whole
  # run, outside any per-example transaction -- a bare create collides with
  # that row's (provider, model_id) unique index.
  let!(:model) do
    Model.find_or_create_by!(model_id: model_id, provider: "ollama") { |m| m.name = model_id }
  end

  before do
    RubyLLM.config.default_model = model_id
    allow(LLM::Registry).to receive(:default_model).and_return(model)
  end

  def stub_llm_response(body)
    stub_request(:post, "http://localhost:11500/v1/chat/completions")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "text/event-stream" })
  end

  # Realistic SSE format for RubyLLM's streaming expectation
  def sse_body(content)
    "data: {\"choices\":[{\"delta\":{\"content\":#{content.inspect}}}]}\n\ndata: [DONE]\n"
  end

  describe "#call" do
    it "updates the job posting with data from the LLM via real HTTP simulation" do
      llm_json = {
        category: "Software Engineering", tags: %w[ruby rails], is_remote: true,
        remote_nuance: "Strictly remote", salary_min: 100_000, salary_max: 150_000, currency: "USD"
      }.to_json
      stub_llm_response(sse_body(llm_json))

      categorizer.call

      job_posting.reload
      expect(job_posting.data["ai_category"]).to eq("Software Engineering")
      expect(job_posting.tags).to contain_exactly("ruby", "rails")
      expect(job_posting.data["is_remote"]).to be true
    end

    it "doesn't clobber salary data already on the posting when the LLM's response omits it" do
      # Promote (e.g. from a structured SmartRecruiters posting) already
      # wrote real salary data before the categorizer ever runs.
      job_posting.update!(data: { "salary_min" => 110_000, "salary_max" => 120_000, "currency" => "USD" })
      llm_json = { category: "Software Engineering", tags: %w[ruby rails] }.to_json
      stub_llm_response(sse_body(llm_json))

      categorizer.call

      job_posting.reload
      expect(job_posting.data["ai_category"]).to eq("Software Engineering")
      expect(job_posting.data["salary_min"]).to eq(110_000)
      expect(job_posting.data["salary_max"]).to eq(120_000)
      expect(job_posting.data["currency"]).to eq("USD")
    end

    it "handles malformed JSON from the LLM gracefully" do
      # LLM returns some chatter before/after valid JSON or just broken stuff
      chatter = "I am thinking... here is your data: { broken json"
      stub_llm_response(sse_body(chatter))

      expect { categorizer.call }.not_to raise_error

      job_posting.reload
      expect(job_posting.data["ai_category"]).to be_nil
    end

    it "extracts JSON surrounded by chatter before and after it" do
      llm_json = { category: "Software Engineering", tags: %w[ruby rails] }.to_json
      chatter = "Sure, here you go:\n#{llm_json}\nLet me know if you need anything else!"
      stub_llm_response(sse_body(chatter))

      categorizer.call

      job_posting.reload
      expect(job_posting.data["ai_category"]).to eq("Software Engineering")
    end

    it "handles LLM failures gracefully" do
      stub_request(:post, "http://localhost:11500/v1/chat/completions")
        .to_return(status: 500, body: "Internal Server Error")
      allow(Rails.logger).to receive(:error)

      categorizer.call

      expect(Rails.logger).to have_received(:error).with(include("execution failed")).at_least(:once)
      expect(Rails.logger).to have_received(:error).with(include("Agent failed for Job"))
    end

    it "skips already-categorized postings unless forced" do
      job_posting.update!(data: { "ai_category" => "Design" })
      allow(JobBoards::CategorizerAgent).to receive(:new)

      categorizer.call

      expect(JobBoards::CategorizerAgent).not_to have_received(:new)
    end

    it "skips expired postings unless forced" do
      job_posting.expire!
      allow(JobBoards::CategorizerAgent).to receive(:new)

      categorizer.call

      expect(JobBoards::CategorizerAgent).not_to have_received(:new)
    end

    it "processes an already-categorized posting when forced" do
      job_posting.update!(data: { "ai_category" => "Design" })
      llm_json = {
        category: "Software Engineering", tags: %w[ruby rails], is_remote: true,
        remote_nuance: "Strictly remote", salary_min: 100_000, salary_max: 150_000, currency: "USD"
      }.to_json
      stub_llm_response(sse_body(llm_json))

      categorizer.call(force: true)

      expect(job_posting.reload.data["ai_category"]).to eq("Software Engineering")
    end
  end
end
