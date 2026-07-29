# frozen_string_literal: true

require "rails_helper"

# Exercises SolidQueueOtel through the real ActiveSupport::Notifications
# round trip rather than hand-building an Event -- event.time/duration are
# derived from Process.clock_gettime(CLOCK_MONOTONIC), not Time.now, and a
# prior incident (see the class comment in the initializer) put 2,122 real
# jobs into failed_executions from a type mismatch in exactly this
# arithmetic. Only a real Event, not a stubbed one, can catch that class of
# regression.
RSpec.describe SolidQueueOtel do
  let(:tracer) { instance_double(OpenTelemetry::Trace::Tracer) }
  let(:span) do
    instance_double(OpenTelemetry::Trace::Span, "status=" => nil, set_attribute: nil, record_exception: nil)
  end

  def capture_notification_args(job:, exception: nil)
    captured = nil
    callback = ->(*args) { captured = args }
    ActiveSupport::Notifications.subscribed(callback, "perform.active_job") { instrument(job, exception) }
    captured
  end

  def instrument(job, exception)
    ActiveSupport::Notifications.instrument("perform.active_job", job: job, exception_object: exception)
  end

  describe ".record_perform" do
    it "emits a span with job/queue/duration/outcome attributes and queue wait time" do
      job = JobBoards::ContentEnrichmentJob.new
      job.enqueued_at = 3.seconds.ago
      args = capture_notification_args(job: job)

      allow(tracer).to receive(:in_span)
        .with("solid_queue.perform", attributes: hash_including(
          "app.job.class" => "JobBoards::ContentEnrichmentJob",
          "app.job.queue" => job.queue_name,
          "app.job.outcome" => "success"
        )).and_yield(span)

      described_class.record_perform(tracer, *args)

      expect(span).to have_received(:set_attribute).with("app.job.queue_wait_ms", a_value >= 0)
    end

    it "records the exception on the span and marks the outcome as an error" do
      job = JobBoards::ContentEnrichmentJob.new
      error = StandardError.new("boom")
      args = capture_notification_args(job: job, exception: error)

      allow(tracer).to receive(:in_span)
        .with("solid_queue.perform", attributes: hash_including("app.job.outcome" => "error"))
        .and_yield(span)

      described_class.record_perform(tracer, *args)

      expect(span).to have_received(:"status=").with(an_instance_of(OpenTelemetry::Trace::Status))
      expect(span).to have_received(:record_exception).with(error)
    end

    it "skips queue wait time when the job has no enqueued_at" do
      job = JobBoards::ContentEnrichmentJob.new
      args = capture_notification_args(job: job)

      allow(tracer).to receive(:in_span).and_yield(span)

      described_class.record_perform(tracer, *args)

      expect(span).not_to have_received(:set_attribute)
    end

    it "swallows errors from span emission so telemetry never fails the job" do
      job = JobBoards::ContentEnrichmentJob.new
      args = capture_notification_args(job: job)
      allow(tracer).to receive(:in_span).and_raise(StandardError, "collector down")

      expect { described_class.record_perform(tracer, *args) }.not_to raise_error
    end
  end
end
