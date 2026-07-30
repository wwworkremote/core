# frozen_string_literal: true

class LLM::Orchestrator
  def self.call(...)
    new(...).call
  end

  # 8 named options on a widely-used public constructor (7 call sites across
  # app/services, app/jobs, app/agents) -- wrapping them in a parameter
  # object would be the textbook Sandi Metz move, but that's an API change
  # rippling through every caller, out of scope for this internal cleanup.
  # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength
  def initialize(untrusted_text:, chat: nil, agent: nil, system_rules: nil, task_instructions: nil, schema: nil,
                 model: nil, metadata: {})
    @untrusted_text = untrusted_text
    @chat = chat
    @agent = agent
    @system_rules = system_rules || default_system_rules
    @task_instructions = task_instructions || default_task_instructions
    @schema = schema
    @model = resolve_model(model)
    @metadata = metadata || {}
  end
  # rubocop:enable Metrics/ParameterLists, Metrics/MethodLength

  def call(&block)
    return format_failure("No model provided or found in registry") unless @model

    tracer = OpenTelemetry.tracer_provider.tracer("llm_orchestrator")
    tracer.in_span("orchestrate_llm_call") { |span| perform_call(span, block) }
  end

  private

  def default_system_rules
    @agent.respond_to?(:system_instructions) ? @agent.system_instructions : "You are a helpful assistant."
  end

  def default_task_instructions
    @agent.respond_to?(:render_instructions) ? @agent.render_instructions : "Process the data."
  end

  def resolve_model(model)
    model || @chat&.model || agent_model || LLM::Registry.default_model || synced_default_model
  end

  # Self-healing: if no model found, attempt one sync (useful for tests/first-run)
  def synced_default_model
    LLM::Registry.sync
    LLM::Registry.default_model
  end

  def agent_model
    return nil unless @agent.respond_to?(:model_id)

    ::Model.find_by(model_id: @agent.model_id)
  end

  def perform_call(span, block)
    span.set_attribute("app.llm.model", @model.model_id)
    guardrail_result = Guardrails::Pipeline.call(@untrusted_text)
    return guardrail_failure(span, guardrail_result) unless guardrail_result.allowed?

    run_with_error_handling(span, guardrail_result.sanitized_text, block)
  end

  def guardrail_failure(span, guardrail_result)
    span.set_attribute("app.guardrails.disposition", "blocked")
    format_failure("Blocked by guardrails: #{guardrail_result.findings.join(', ')}")
  end

  def run_with_error_handling(span, sanitized_text, block)
    execute_with_model(@model, sanitized_text, span, block)
  rescue ActiveRecord::ConnectionTimeoutError => e
    fail_timeout(span, e)
  rescue StandardError => e
    fail_execution(span, e)
  end

  def fail_timeout(span, error)
    log_and_fail(span, "Database connection timeout: #{error.message}. Pool is likely exhausted.",
                 "DB Connection Timeout: #{error.message}", "Database connection timeout. Please try again later.")
  end

  def fail_execution(span, error)
    log_and_fail(span, "Model (#{@model.model_id}) execution failed: #{error.message}.",
                 error.message, "Model execution failed: #{error.message}")
  end

  def log_and_fail(span, log_message, span_message, user_message)
    Rails.logger.error "[Orchestrator] #{log_message}"
    span.status = OpenTelemetry::Trace::Status.error(span_message)
    format_failure(user_message)
  end

  def execute_with_model(model, sanitized_text, span, block)
    span.add_event("sending_llm_request", attributes: { "model" => model.model_id.to_s })
    chat = @chat || LLMChat.create!(model: model)
    seed_chat_messages(chat, sanitized_text)
    message = Streamer.call(chat, model, block)
    { success: true, model: model.model_id, output: ResponseRecorder.call(chat, model, message, span) }
  end

  # If untrusted_text was provided and this is a new/empty chat, establish
  # context. Most chat loops already add the user message before enqueuing
  # the job, so an existing chat with a matching last user message is left
  # alone.
  def seed_chat_messages(chat, sanitized_text)
    return unless chat.llm_messages.empty?

    chat.llm_messages.create!(role: "system", content: @system_rules) if @system_rules.present?
    chat.llm_messages.create!(role: "user", content: "#{sanitized_text}\n\n#{@task_instructions}")
  end

  def format_failure(reason)
    { success: false, error: reason }
  end
end
