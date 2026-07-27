# frozen_string_literal: true

require "rails_helper"
require "net/http"

# Live integration specs for the llama.cpp inference stack.
#
# These specs require a running llama.cpp server (llama-ctl start).
# They are excluded from the normal suite and must be run explicitly:
#
#   bundle exec rspec spec/integration/llm_live_spec.rb --tag live
#   # or
#   RUN_LIVE_SPECS=1 bundle exec rspec spec/integration/llm_live_spec.rb
#
# For CI pre-flight use bin/verify_llm.rb instead (no Rails boot required).

LLAMA_BASE = ENV.fetch("OLLAMA_API_BASE", "http://127.0.0.1:11500/v1").sub(%r{/v1/?$}, "").freeze

RSpec.describe "llama.cpp live integration", :live do
  # ── Server sanity ──────────────────────────────────────────────────────────

  describe "server health" do
    it "responds ok at /health" do
      uri = URI("#{LLAMA_BASE}/health")
      res = Net::HTTP.get_response(uri)
      expect(res.code).to eq("200")
      body = JSON.parse(res.body)
      expect(body["status"]).to be_in(["ok", "loading model"])
    end

    it "exposes 'local' as a model alias at /v1/models" do
      uri = URI("#{LLAMA_BASE}/v1/models")
      res = Net::HTTP.get_response(uri)
      expect(res.code).to eq("200")
      ids = JSON.parse(res.body)["data"]&.pluck("id")
      expect(ids).to include("local"),
                     "Expected 'local' alias. Got: #{ids.inspect}\n" \
                     "Fix: ensure llama-server is started with --alias local (llama-ctl restart)"
    end
  end

  # ── Embeddings ─────────────────────────────────────────────────────────────

  describe JobBoards::Embedder do
    describe ".embed_text" do
      it "returns a float vector for a plain-text input" do
        vector = described_class.embed_text("Senior Rails Engineer, remote, competitive salary")
        expect(vector).to be_an(Array),
                          "Expected Array, got #{vector.inspect[0, 80]}. " \
                          "Fix: ensure server started with --embeddings (llama-ctl restart)"
        expect(vector).not_to be_empty
        expect(vector.first).to be_a(Numeric)
        expect(vector.length).to be > 100 # any reasonable embedding model is > 100-dim
      end

      it "returns different vectors for semantically different inputs" do
        v1 = described_class.embed_text("Ruby on Rails backend engineer")
        v2 = described_class.embed_text("marine biology fieldwork expedition")
        expect(v1).not_to eq(v2)
      end

      it "returns nil gracefully when ENABLE_EMBEDDINGS=false" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("ENABLE_EMBEDDINGS").and_return("false")
        expect(described_class.embed_text("anything")).to be_nil
      end
    end
  end

  # ── Inference via Orchestrator ─────────────────────────────────────────────

  describe LLM::Orchestrator do
    let(:local_model) do
      model_id = LLM::Registry.default_model_id
      Model.find_or_create_by!(model_id: model_id) do |m|
        m.provider           = "ollama"
        m.name               = "Qwen 2.5 Coder 7B (Local)"
        m.family             = "qwen"
        m.context_window     = 32_768
        m.max_output_tokens  = 2_048
      end
    end

    it "returns a successful response for a simple prompt", :aggregate_failures do
      result = described_class.call(
        untrusted_text: "Respond with exactly the token INFERENCE_OK and nothing else.",
        model: local_model,
        system_rules: "You are a test assistant. Follow instructions exactly.",
        task_instructions: ""
      )
      expect(result[:success]).to be(true), "Inference failed: #{result[:error]}"
      expect(result[:output].to_s).to include("INFERENCE_OK")
    end

    it "blocks content that fails guardrails" do
      allow(Guardrails::Pipeline).to receive(:call)
        .and_return(double("r", allowed?: false, findings: ["test block"]))
      result = described_class.call(untrusted_text: "anything", model: local_model)
      expect(result[:success]).to be(false)
      expect(result[:error]).to match(/guardrails/i)
    end
  end
end
