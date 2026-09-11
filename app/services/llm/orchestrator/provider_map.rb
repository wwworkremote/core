# frozen_string_literal: true

module LLM::Orchestrator::ProviderMap
  PROVIDERS = {
    anthropic: RubyLLM::Providers::Anthropic,
    azure: RubyLLM::Providers::Azure,
    bedrock: RubyLLM::Providers::Bedrock,
    deepseek: RubyLLM::Providers::DeepSeek,
    gemini: RubyLLM::Providers::Gemini,
    gpustack: RubyLLM::Providers::GPUStack,
    mistral: RubyLLM::Providers::Mistral,
    ollama: RubyLLM::Providers::Ollama,
    openai: RubyLLM::Providers::OpenAI,
    openrouter: RubyLLM::Providers::OpenRouter,
    perplexity: RubyLLM::Providers::Perplexity,
    vertexai: RubyLLM::Providers::VertexAI,
    xai: RubyLLM::Providers::XAI
  }.freeze
end
