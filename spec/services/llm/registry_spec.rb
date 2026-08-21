# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::Registry do
  let(:config_content) do
    <<~YAML
      models:
        "llama3.2:latest":
          provider: "ollama"
          name: "Llama 3.2"
          family: "llama"
          context_window: 131072
          max_output_tokens: 4096
      defaults:
        primary: "llama3.2:latest"
    YAML
  end

  before do
    described_class.instance_variable_set(:@default_model_id, nil)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(described_class::CONFIG_PATH).and_return(true)
    allow(YAML).to receive(:load_file).and_call_original
    allow(YAML).to receive(:load_file).with(described_class::CONFIG_PATH).and_return(YAML.safe_load(config_content))
  end

  describe ".sync" do
    it "creates or updates models from config" do
      expect {
        described_class.sync
      }.to change(Model, :count).by(1)

      model = Model.find_by(model_id: "llama3.2:latest")
      expect(model.provider).to eq("ollama")
      expect(model.name).to eq("Llama 3.2")
    end
  end

  describe ".default_model" do
    it "returns the default model instance" do
      described_class.sync
      model = described_class.default_model
      expect(model.model_id).to eq("llama3.2:latest")
    end
  end

  describe ".model_for" do
    before { described_class.sync }

    it "returns the model named by a per-purpose default" do
      expect(described_class.model_for(:primary).model_id).to eq("llama3.2:latest")
    end

    # nil rather than raising: an unconfigured purpose has to fall through to
    # the primary, or pointing one call site at a different model would mean
    # configuring every other one.
    it "returns nil for a purpose with no configured default" do
      expect(described_class.model_for(:answer_generation)).to be_nil
    end

    # Same reason a typo shouldn't be fatal -- the caller falls back rather
    # than every LLM path failing on a bad config key.
    it "returns nil when the configured model has not been synced" do
      allow(YAML).to receive(:load_file).with(described_class::CONFIG_PATH)
                                        .and_return({ "defaults" => { "answer_generation" => "nope" } })

      expect(described_class.model_for(:answer_generation)).to be_nil
    end
  end
end
