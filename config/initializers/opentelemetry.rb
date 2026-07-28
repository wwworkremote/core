# frozen_string_literal: true

require "opentelemetry/sdk"
require "opentelemetry/instrumentation/all"
require "opentelemetry-exporter-otlp"

# Defer OTel configuration until after the application is initialized
# and ensure it handles forking correctly for macOS safety
Rails.application.config.after_initialize do
  # Disable OTel if we are in a sub-process that hasn't fully booted
  # or if we are on macOS and want to avoid the fork segfault
  # Also disable if explicitly requested
  next if ENV["SKIP_OTEL"] || (defined?(Puma) && Puma.respond_to?(:jruby?) && Puma.jruby?)

  configure_otel = lambda do
    OpenTelemetry::SDK.configure do |c|
      c.service_name = "wwworkremote"
      c.use "OpenTelemetry::Instrumentation::Rails"
      c.use "OpenTelemetry::Instrumentation::PG"
      c.use "OpenTelemetry::Instrumentation::Faraday"
      c.use "OpenTelemetry::Instrumentation::RubyLLM"
    end
  rescue StandardError => e
    Rails.logger.warn "[OTel] Failed to initialize: #{e.message}"
  end

  configure_otel.call

  # MacOS Fork Safety: BatchSpanProcessor's Mutex objects are created once and
  # never reset on fork (only its span buffer/thread are, via reset_on_fork) --
  # if Solid Queue forks a worker while the parent's background export thread
  # holds @export_mutex mid-flush, the child inherits that Mutex's state with
  # no owning thread, which can corrupt the next gzip-compressed export
  # ("gzip: invalid header" from a torn Zlib stream). Confirmed via jobs.log:
  # happened exactly at process shutdown/restart boundaries, never during
  # live operation. Solid Queue's on_start hook runs after boot, inside each
  # forked child (Processes::Runnable#start -> fork(&block) -> boot -> Life-
  # cycleHooks#run_start_hooks), so reconfiguring OTel there discards the
  # fork-inherited Mutex objects and builds fresh ones per child.
  if defined?(SolidQueue)
    [SolidQueue::Worker, SolidQueue::Dispatcher, SolidQueue::Scheduler].each do |klass|
      klass.on_start { configure_otel.call }
    end
  end
end
