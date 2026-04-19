# frozen_string_literal: true

module Llm
  class Orchestrator
    def self.call(...)
      new(...).call
    end

    def initialize(untrusted_text:, chat: nil, agent: nil, system_rules: nil, task_instructions: nil, schema: nil, model: nil, metadata: {})
      @untrusted_text = untrusted_text
      @chat = chat
      @agent = agent
      @system_rules = system_rules || (agent.respond_to?(:system_instructions) ? agent.system_instructions : "You are a helpful assistant.")
      @task_instructions = task_instructions || (agent.respond_to?(:render_instructions) ? agent.render_instructions : "Process the data.")
      @schema = schema
      @model = model || @chat&.model || agent_model || Llm::Registry.default_model
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

        # 2. Execution with Potential Escalation
        begin
          execute_with_model(@model, guardrail_result.sanitized_text, span, &block)
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
              execute_with_model(fallback_model, guardrail_result.sanitized_text, span, &block)
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

    def execute_with_model(model, sanitized_text, span, &block)
      span.add_event('sending_llm_request', attributes: { 'model' => model.model_id })
      
      chat = @chat || LlmChat.create!(model: model)
      
      # Ensure system rules are present
      if @system_rules.present? && chat.llm_messages.none? { |m| m.role == 'system' }
        chat.llm_messages.create!(role: 'system', content: @system_rules)
      end
      
      full_prompt = @task_instructions.present? ? "#{@task_instructions}\n\n#{sanitized_text}" : sanitized_text
      
      # If @chat was provided, we assume the user message was already created (e.g. by controller)
      # with the simple sanitized_text. We'll update it to the full_prompt for the LLM.
      user_message = nil
      if @chat
        user_message = @chat.llm_messages.where(role: 'user').last
        if user_message && (user_message.content == sanitized_text || user_message.content == @untrusted_text)
          user_message.update!(content: full_prompt)
        else
          user_message = @chat.llm_messages.create!(role: 'user', content: full_prompt)
        end
      else
        user_message = chat.llm_messages.create!(role: 'user', content: full_prompt)
      end

      # Create placeholder for assistant response to enable streaming
      assistant_message = chat.llm_messages.create!(role: 'assistant', content: '')
      
      # Use the model's chat API directly to avoid RubyLLM's automatic message creation in chat.ask
      messages = chat.llm_messages.where("id <= ?", assistant_message.id).order(:id).map do |m|
        { role: m.role, content: m.content }
      end
      # Remove the empty assistant message from the payload for the LLM
      messages.pop if messages.last[:role] == 'assistant' && messages.last[:content].blank?

      response = model.chat(messages: messages) do |chunk|
        if chunk.content.present?
          assistant_message.content += chunk.content
          # Broadcast the chunk to the UI
          assistant_message.broadcast_append_chunk(chunk.content)
        end
        yield chunk if block_given?
      end
      
      span.add_event('received_llm_response')
      assistant_message.save!

      text = assistant_message.content

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
