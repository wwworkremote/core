# frozen_string_literal: true

# RubyLLM's client.complete expects a model: object standing in for
# RubyLLM::Model::Info. `.id` is enough for the Ollama/OpenAI path, which is
# why this was a one-attribute Struct and why the Anthropic path had never
# actually run -- that provider also reads `.max_tokens` (as
# `model.max_tokens || 4096`) and `.reasoning_option`.
#
# max_tokens mirrors RubyLLM::Model::Info#max_tokens, which is just an alias
# for max_output_tokens -- the value config/models.yml already carries per
# model, so a model configured for 8192 no longer silently gets 4096.
#
# reasoning_option returns nil for every type: no model here is configured
# for extended thinking, and nil is what Info returns when the option isn't
# set, so the provider takes its non-thinking path.
LLM::Orchestrator::ModelRef = Struct.new(:id, :max_tokens) do
  def reasoning_option(_type)
    nil
  end
end
