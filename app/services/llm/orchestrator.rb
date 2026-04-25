# frozen_string_literal: true

require "ostruct"

class LLM::Orchestrator
  def self.call(...)
    new(...).call
  end

  def initialize(untrusted_text:, chat: nil, agent: nil, system_rules: nil, task_instructions: nil, schema: nil,
                 model: nil, metadata: {})
    @untrusted_text = untrusted_text
    @chat = chat
    @agent = agent
    @system_rules = system_rules ||
                    (agent.respond_to?(:system_instructions) ? agent.system_instructions : "You are a helpful assistant.")
    @task_instructions = task_instructions ||
                         (agent.respond_to?(:render_instructions) ? agent.render_instructions : "Process the data.")
    @schema = schema
    @model = model || @chat&.model || agent_model || LLM::Registry.default_model
    @metadata = metadata
  end

  def call(&)
    tracer = OpenTelemetry.tracer_provider.tracer("llm_orchestrator")

    # Ensure all metadata keys are strings for OTel
    stringified_metadata = @metadata.transform_keys(&:to_s)

    tracer.in_span("orchestrate_llm_call",
                   attributes: { "app.llm.model" => @model&.model_id }.merge(stringified_metadata)) do |span|
      unless @model
        span.status = OpenTelemetry::Trace::Status.error("No model provided or found in registry")
        return format_failure("No model provided or found in registry")
      end

      # 1. Inbound Guardrails
      guardrail_result = Guardrails::Pipeline.call(@untrusted_text)
      unless guardrail_result.allowed?
        span.set_attribute("app.guardrails.disposition", "blocked")
        return format_failure("Blocked by guardrails: #{guardrail_result.findings.join(', ')}")
      end

      # 2. Execution (No fallback/escalation for local-only)
      begin
        execute_with_model(@model, guardrail_result.sanitized_text, span, &)
      rescue ActiveRecord::ConnectionTimeoutError => e
        Rails.logger.error "[Orchestrator] Database connection timeout: #{e.message}. Pool is likely exhausted."
        span.status = OpenTelemetry::Trace::Status.error("DB Connection Timeout: #{e.message}")
        format_failure("Database connection timeout. Please try again later.")
      rescue StandardError => e
        Rails.logger.error "[Orchestrator] Model (#{@model.model_id}) execution failed: #{e.message}."
        span.status = OpenTelemetry::Trace::Status.error(e.message)
        format_failure("Model execution failed: #{e.message}")
      end
    end
  end

  private

  def agent_model
    return nil unless @agent.respond_to?(:model_id)
    ::Model.find_by(model_id: @agent.model_id)
  end

  def execute_with_model(model, sanitized_text, span, &)
    span.add_event("sending_llm_request", attributes: { "model" => model.model_id })

    chat = @chat || LLMChat.create!(model: model)

    # If this is a new or empty chat, establish the context
    # If untrusted_text was provided and not yet in messages, add it as a user message
    if chat.llm_messages.empty?
      chat.llm_messages.create!(role: "system", content: @system_rules) if @system_rules.present?
      chat.llm_messages.create!(role: "user", content: "#{sanitized_text}\n\n#{@task_instructions}")
    elsif sanitized_text.present? && chat.llm_messages.where(role: "user").last&.content != sanitized_text
      # Optional: Add the latest prompt if it is different from the last message
      # In most chat loops, the user message is already added before the job is enqueued.
    end

    # Correct RubyLLM registry resolution
    provider_map = {
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
    }

    provider_class = provider_map[model.provider.to_sym]
    raise "Unknown provider: #{model.provider}" unless provider_class

    client = provider_class.new(RubyLLM.config)

    # Wrap messages in OpenStruct to satisfy RubyLLM's expectation for .role and .content methods
    llm_messages = chat.llm_messages.order(:id).map do |m|
      OpenStruct.new(
        role: m.role,
        content: m.content,
        tool_calls: nil,
        tool_call_id: nil,
        thinking_text: nil,
        thinking_signature: nil
      )
    end

    full_output = +""

    # Use the native complete pattern to stream content directly
    client.complete(
      llm_messages,
      tools: [],
      temperature: 0.7,
      model: OpenStruct.new(id: model.model_id)
    ) do |chunk|
      # chunk is a RubyLLM::Chunk object, we need its content
      text = chunk.content.to_s
      full_output << text
      yield text if block_given?
    end

    # Save the final response to the chat history
    chat.llm_messages.create!(role: "assistant", content: full_output) if full_output.present?

    span.add_event("received_llm_response")
    { success: true, model: model.model_id, output: full_output }
  end

  def format_failure(reason)
    { success: false, error: reason }
  end
end
