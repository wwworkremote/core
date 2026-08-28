# frozen_string_literal: true

# Small interface for business-process telemetry. Callers emit facts; the
# subscriber turns those facts into spans. Telemetry is deliberately unable to
# interrupt the operation it observes.
module Wwwr::ProcessSignals
  EVENT_NAME = "wwworkremote.process_signal"
  ATTRIBUTES = %i[signal process stage outcome provider phase job_class].freeze

  module_function

  def emit(signal, attributes = {})
    payload = { signal: signal.to_s }.merge(attributes.slice(*ATTRIBUTES))
    ActiveSupport::Notifications.instrument(EVENT_NAME, payload)
  rescue StandardError => e
    Rails.logger.warn "[ProcessSignals] Emission failed: #{e.class}: #{e.message}"
    nil
  end

  def record(tracer, payload)
    tracer.in_span(span_name(payload), attributes: span_attributes(payload)) { |span| record_span_event(span) }
  rescue StandardError => e
    Rails.logger.warn "[ProcessSignals] Span failed: #{e.class}: #{e.message}"
    nil
  end

  def span_name(payload)
    "wwr.process.#{payload.fetch(:signal)}"
  end

  def record_span_event(span)
    span.add_event("business_process_signal")
  end

  def span_attributes(payload)
    payload.slice(*ATTRIBUTES).each_with_object({}) do |(key, value), result|
      result["app.process.#{key}"] = value.to_s
    end
  end
end
