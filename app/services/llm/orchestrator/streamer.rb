# frozen_string_literal: true

# Handles the actual provider call + chunk streaming for
# LLM::Orchestrator#execute_with_model -- split out to keep the
# orchestrator itself under Metrics/ClassLength.
class LLM::Orchestrator::Streamer
  def self.call(chat, model, block)
    new(chat, model, block).call
  end

  def initialize(chat, model, block)
    @chat = chat
    @model = model
    @block = block
  end

  # Returns the full RubyLLM::Message (content + token/cost usage), not
  # just the accumulated text -- client.complete's return value carries
  # usage data the caller needs for telemetry, which a plain string can't.
  def call
    client.complete(llm_messages, **stream_args) { |chunk| stream_chunk(chunk) }
  end

  private

  def client
    provider_class = LLM::Orchestrator::ProviderMap::PROVIDERS[@model.provider.to_sym]
    raise "Unknown provider: #{@model.provider}" unless provider_class

    provider_class.new(RubyLLM.config)
  end

  def llm_messages
    @chat.llm_messages.order(:id).map { |m| to_provider_message(m) }
  end

  def to_provider_message(message)
    LLM::Orchestrator::ProviderMessage.new(message.role, message.content, nil, nil, nil, nil)
  end

  def stream_args
    { tools: [], temperature: 0.7, model: LLM::Orchestrator::ModelRef.new(@model.model_id) }
  end

  def stream_chunk(chunk)
    @block&.call(chunk.content.to_s)
  end
end
