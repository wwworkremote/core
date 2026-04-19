# frozen_string_literal: true

module Llm
  class Orchestrator
    def self.call(...)
      new(...).call
    end

    def initialize(untrusted_text:, agent: nil, system_rules: nil, task_instructions: nil, schema: nil, model: nil, metadata: {})
      @untrusted_text = untrusted_text
      @agent = agent
      @system_rules = system_rules || (agent.respond_to?(:system_instructions) ? agent.system_instructions : "You are a helpful assistant.")
      @task_instructions = task_instructions || (agent.respond_to?(:render_instructions) ? agent.render_instructions : "Process the data.")
      @schema = schema
      @model = model || agent_model || Llm::Registry.default_model
      @metadata = metadata
    end

    def call(&block)
      tracer = OpenTelemetry.tracer_provider.tracer('llm_orchestrator')
      
      # Ensure all metadata keys are strings for OTel
      stringified_metadata = @metadata.transform_keys(&:to_s)
      
      tracer.in_span('orchestrate_llm_call', attributes: { 'app.llm.model' => @model&.model_id }.merge(stringified_metadata)) do |span|
        unless @model
          span.status = OpenTelemetry::Trace::Status.error("No model provided or found in registry")
          return format_failure("No model provided or found in registry")
        end

        # 1. Inbound Guardrails
        guardrail_result = Guardrails::Pipeline.call(@untrusted_text)
        unless guardrail_result.allowed?
          span.set_attribute('app.guardrails.disposition', 'blocked')
          return format_failure("Blocked by guardrails: #{guardrail_result.findings.join(', ')}")
        end

        # 2. Build Prompt
        prompt = Guardrails::PromptBuilder.new(
          @system_rules,
          @task_instructions,
          guardrail_result.sanitized_text
        ).call

        # 3. Execution with Potential Escalation
        begin
          execute_with_model(@model, prompt, span, &block)
        rescue ActiveRecord::ConnectionTimeoutError => e
          Rails.logger.error "[Orchestrator] Database connection timeout: #{e.message}. Pool is likely exhausted."
          span.status = OpenTelemetry::Trace::Status.error("DB Connection Timeout: #{e.message}")
          format_failure("Database connection timeout. Please try again later.")
        rescue StandardError => e
          Rails.logger.warn "[Orchestrator] Primary model (#{@model.model_id}) failed: #{e.message}. Escalating..."
          span.add_event('primary_model_failed', attributes: { 'error' => e.message, 'model' => @model.model_id })
          
          begin
            fallback_model_id = YAML.load_file(Llm::Registry::CONFIG_PATH).dig('defaults', 'fallback')
            fallback_model = ::Model.find_by(model_id: fallback_model_id)
            
            if fallback_model && fallback_model != @model
              span.set_attribute('app.llm.escalated', true)
              execute_with_model(fallback_model, prompt, span, &block)
            else
              span.status = OpenTelemetry::Trace::Status.error(e.message)
              format_failure("Model execution failed and no fallback available: #{e.message}")
            end
          rescue ActiveRecord::ConnectionTimeoutError => conn_e
            Rails.logger.error "[Orchestrator] Database connection timeout during escalation: #{conn_e.message}"
            span.status = OpenTelemetry::Trace::Status.error("DB Connection Timeout during escalation: #{conn_e.message}")
            format_failure("Database connection timeout during escalation.")
          rescue StandardError => fallback_e
            span.status = OpenTelemetry::Trace::Status.error(fallback_e.message)
            format_failure("Both primary and fallback models failed. Fallback error: #{fallback_e.message}")
          end
        end
      end
    end

    private

    def agent_model
      return nil unless @agent.respond_to?(:model_id)
      ::Model.find_by(model_id: @agent.model_id)
    end

    def execute_with_model(model, prompt, span, &block)
      span.add_event('sending_llm_request', attributes: { 'model' => model.model_id })
      chat = LlmChat.create!(model: model)
      response = chat.ask(prompt, &block)
      span.add_event('received_llm_response')

      text = response.content.is_a?(String) ? response.content : response.content.text

      # 4. Outbound Validation
      output_guard = Guardrails::OutputValidator.new(text, schema: @schema).call
      unless output_guard[:valid]
        span.set_attribute('app.guardrails.output_valid', false)
        return format_failure("Output validation failed: #{output_guard[:findings].join(', ')}")
      end

      span.set_attribute('app.guardrails.output_valid', true)
      { success: true, output: text, model: model.model_id }
    end

    def format_failure(reason)
      { success: false, error: reason }
    end
  end
end
