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
      tracer = OpenTelemetry.tracer_provider.tracer('categorizer')
      tracer.in_span('categorize_job', attributes: { 'app.job_posting.id' => @job_posting.id }) do |span|
        model = Model.find_by(model_id: 'llama3.2:1b', provider: 'ollama')
        unless model
          span.add_event('model_not_found')
          return
        end

        chat = LlmChat.create!(model: model)

        prompt = <<~PROMPT
          Analyze the following job posting and categorize it.
          Title: #{@job_posting.title}
          Company: #{@job_posting.company}
          Description: #{@job_posting.body&.truncate(2000)}

          Return a JSON object with:
          1. "category": Must be one of: #{CATEGORIES.join(', ')}
          2. "tags": An array of up to 5 technical keywords or skills mentioned.

          Example: {"category": "Software Engineering", "tags": ["ruby", "rails", "postgresql"]}
          Return ONLY the JSON.
        PROMPT

        span.add_event('sending_llm_request')
        response = chat.ask(prompt)
        span.add_event('received_llm_response')

        parsed = parse_response(response)

        if parsed
          span.set_attribute('app.job_posting.category', parsed['category'])
          @job_posting.update(
            tags: parsed['tags'],
            data: @job_posting.data.merge('ai_category' => parsed['category'])
          )
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
