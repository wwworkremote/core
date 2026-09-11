# frozen_string_literal: true

require "rails_helper"

RSpec.describe Wwwr::ProcessSignals do
  it "emits a normalized business signal through ActiveSupport notifications" do
    received = nil
    subscriber = ActiveSupport::Notifications.subscribe("wwworkremote.process_signal") { |*args| received = args }

    described_class.emit(:lead_observed, provider: "greenhouse", outcome: "success", ignored: "dropped")

    payload = received.last
    expect(payload).to include(signal: "lead_observed", provider: "greenhouse", outcome: "success")
    expect(payload).not_to have_key(:ignored)
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  it "swallows notification failures so observation cannot fail the operation" do
    allow(ActiveSupport::Notifications).to receive(:instrument).and_raise(StandardError, "collector down")

    expect { described_class.emit(:lead_observed) }.not_to raise_error
  end

  it "records a signal as an OpenTelemetry span with stable attributes" do
    tracer = instance_double(OpenTelemetry::Trace::Tracer)
    span = instance_double(OpenTelemetry::Trace::Span, add_event: nil)
    allow(tracer).to receive(:in_span).and_yield(span)

    described_class.record(tracer, signal: "lead_observed", provider: "greenhouse", outcome: "success")

    expect(tracer).to have_received(:in_span).with("wwr.process.lead_observed", attributes: {
                                                     "app.process.signal" => "lead_observed",
                                                     "app.process.provider" => "greenhouse",
                                                     "app.process.outcome" => "success"
                                                   })
  end

  it "swallows span failures" do
    tracer = instance_double(OpenTelemetry::Trace::Tracer)
    allow(tracer).to receive(:in_span).and_raise(StandardError, "collector down")

    expect { described_class.record(tracer, signal: "lead_observed") }.not_to raise_error
  end
end
