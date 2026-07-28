# frozen_string_literal: true

# Emits Solid Queue golden-signal spans to the existing OTel Collector -> O2
# pipeline. No opentelemetry-metrics-sdk/-api gem is in the bundle (only
# tracing), so this uses spans rather than a metrics API: O2 can derive
# latency percentiles and error rates from span duration/status the same way
# it would from a metrics stream. Follows the same
# OpenTelemetry.tracer_provider.tracer(...).in_span pattern already used in
# LLM::Orchestrator.
#
# Before this, there was no way to answer "was the queue backed up at 3am"
# without manual SQL archaeology (done repeatedly during the 2026-07-27
# Solid Queue cleanup -- TASK-19/21/22/23/24/25/26/30). Only mission_control-
# jobs' live snapshot existed; nothing was queryable after the fact (TASK-27).
module SolidQueueOtel
  module_function

  # A subscriber that raises here gets treated by ActiveJob's instrumentation
  # as the JOB ITSELF failing -- confirmed the hard way: a TypeError bug in
  # this exact method (event.time is Unix epoch seconds as a Float, not a
  # Time; job.enqueued_at is a real Time -- subtracting them without a
  # matching .to_f raised) put 2,122 real jobs into failed_executions across
  # nearly every job class, none of which had anything to do with their own
  # logic. Telemetry code must never be able to fail the thing it's observing.
  def record_perform(tracer, *)
    event = ActiveSupport::Notifications::Event.new(*)
    job = event.payload[:job]
    exception = event.payload[:exception_object]

    tracer.in_span("solid_queue.perform", attributes: span_attributes(event, job, exception)) do |span|
      record_outcome(span, job, event, exception)
    end
  rescue StandardError => e
    Rails.logger.warn "[SolidQueueOTel] Span emission failed (job unaffected): #{e.class}: #{e.message}"
  end

  def span_attributes(event, job, exception)
    {
      "app.job.class" => job.class.name,
      "app.job.queue" => job.queue_name,
      "app.job.duration_ms" => event.duration.round(2),
      "app.job.outcome" => exception ? "error" : "success"
    }
  end

  def record_outcome(span, job, event, exception)
    if exception
      span.status = OpenTelemetry::Trace::Status.error(exception.message)
      span.record_exception(exception)
    end

    # Queue wait time (enqueue -> perform start), when Solid Queue populated it.
    return unless job.enqueued_at

    wait_ms = ((event.time - job.enqueued_at.to_f) * 1000).round(2)
    span.set_attribute("app.job.queue_wait_ms", wait_ms)
  end
end

Rails.application.config.after_initialize do
  next if ENV["SKIP_OTEL"]

  tracer = OpenTelemetry.tracer_provider.tracer("solid_queue")
  ActiveSupport::Notifications.subscribe("perform.active_job") do |*args|
    SolidQueueOtel.record_perform(tracer, *args)
  end
end
