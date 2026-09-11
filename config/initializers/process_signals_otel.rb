# frozen_string_literal: true

# Business-process signals share the existing OTel exporter but have their own
# named span seam so a healthy queue cannot be mistaken for a healthy product.
Rails.application.config.after_initialize do
  next if ENV["SKIP_OTEL"]

  tracer = OpenTelemetry.tracer_provider.tracer("wwworkremote.process")
  ActiveSupport::Notifications.subscribe(Wwwr::ProcessSignals::EVENT_NAME) do |*args|
    Wwwr::ProcessSignals.record(tracer, args.last)
  end

  ActiveSupport::Notifications.subscribe("perform.active_job") do |*args|
    event = args.last
    Wwwr::ProcessSignals.emit(:queue_job_completed, process: "background_processing", stage: "queue",
                                                    outcome: event[:exception_object] ? "error" : "success",
                                                    job_class: event[:job].class.name)
  end
end
