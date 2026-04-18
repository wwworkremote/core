# frozen_string_literal: true

module JobBoards
  class Categorizer
    CATEGORIES = [
      'Software Engineering',
      'Data Science',
      'Product Management',
      'Design',
      'Marketing',
      'Sales',
      'Customer Support',
      'Operations',
      'Other'
    ].freeze

    def initialize(job_posting)
      @job_posting = job_posting
    end

    def call
      model_id = 'Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf'
      model = Model.find_by(model_id: model_id, provider: 'ollama')
      return unless model

      # 1. Guardrail Inbound Text
      guardrail_result = Guardrails::Pipeline.call(@job_posting.body)
      unless guardrail_result.allowed?
        Rails.logger.warn "[Categorizer] Job #{@job_posting.id} blocked by guardrails: #{guardrail_result.findings.join(', ')}"
        return
      end

      tracer = OpenTelemetry.tracer_provider.tracer('categorizer')
      tracer.in_span('categorize_job', attributes: { 'app.job_posting.id' => @job_posting.id }) do |span|
        chat = LlmChat.create!(model: model)

        system_rules = "You are a professional job categorizer. Return ONLY valid JSON."
        task_instructions = <<~INST
          Task: Categorize the following job posting.
          The "category" MUST be exactly one of: #{CATEGORIES.join(', ')}.
          If unsure, use "Other".
          The "tags" should be 1-5 technical keywords.
          Return ONLY valid JSON. No preamble, no explanation.

          Expected JSON Format:
          {"category": "Software Engineering", "tags": ["ruby", "rails"]}
        INST

        # Use PromptBuilder for untrusted content
        prompt = Guardrails::PromptBuilder.new(
          system_rules,
          task_instructions,
          guardrail_result.sanitized_text.truncate(2000)
        ).call

        span.add_event('sending_llm_request')
        response = chat.ask(prompt)
        span.add_event('received_llm_response')

        text = response.content.is_a?(String) ? response.content : response.content.text
        
        # 2. Guardrail Outbound Text
        output_guard = Guardrails::OutputValidator.new(text, schema: { 'category' => String, 'tags' => Array }).call
        unless output_guard[:valid]
          span.add_event('output_validation_failed', attributes: { 'app.guardrails.findings' => output_guard[:findings].join(', ') })
          return
        end

        parsed = parse_response(text)

        if parsed
          span.set_attribute('app.job_posting.category', parsed['category'])
          @job_posting.update(
            tags: parsed['tags'],
            data: @job_posting.data.merge('ai_category' => parsed['category'])
          )
          span.add_event('categorized', attributes: { 'app.job_posting.category' => parsed['category'] })
        else
          span.add_event('parse_failed')
        end
      end
    rescue StandardError => e
      Rails.logger.error "[Categorizer] Error for Job #{@job_posting.id}: #{e.message}"
      OpenTelemetry::Trace.current_span&.record_exception(e)
      OpenTelemetry::Trace.current_span&.status = OpenTelemetry::Trace::Status.error(e.message)
    end

    private

    def parse_response(response)
      # Basic JSON extraction in case the LLM adds chatter
      json_match = response.match(/\{.*\}/m)
      return nil unless json_match

      JSON.parse(json_match[0])
    rescue JSON::ParserError
      nil
    end
  end
end
