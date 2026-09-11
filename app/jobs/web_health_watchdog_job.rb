# frozen_string_literal: true

# TASK-141: the launchd web service (com.wwworkremote.web) periodically wedges --
# puma keeps the listen socket but stops answering, and since the process never
# exits, launchd KeepAlive never fires. Puma's own worker_timeout doesn't catch
# it either (the wedge doesn't stop the worker heartbeat). This job runs in the
# *jobs* process, which is unaffected, and is the only thing that reliably
# recovers the web process: probe HTTP liveness once a minute, and after two
# consecutive misses, kick the launchd service.
#
# Local only, and a no-op unless the launchd agent is actually loaded -- so it
# never fights a `bin/dev` puma or does anything in CI/prod.
class WebHealthWatchdogJob < ApplicationJob
  queue_as :low

  LABEL = "com.wwworkremote.web"
  # robots.txt is served by ActionDispatch::Static -- exercises puma's full
  # accept -> reactor -> thread-pool path (which is what wedges) without
  # touching routing or the DB. Any HTTP response at all means puma is alive;
  # only a connection failure / timeout counts as wedged.
  PROBE_URI = URI("http://127.0.0.1:#{ENV.fetch('PORT', 31_000)}/robots.txt").freeze
  FAIL_FILE = Rails.root.join("tmp/web_watchdog_consecutive_failures")
  RESTART_AFTER = 2

  def perform
    return unless Rails.env.local?
    return unless service_loaded?

    return FileUtils.rm_f(FAIL_FILE) if puma_answering?

    restart! if record_failure >= RESTART_AFTER
  end

  private

  def record_failure
    failures = (FAIL_FILE.exist? ? FAIL_FILE.read.to_i : 0) + 1
    FAIL_FILE.write(failures.to_s)
    failures
  end

  def restart!
    Rails.logger.warn("[WebHealthWatchdog] #{LABEL} unresponsive -- kickstarting")
    system("launchctl", "kickstart", "-k", "gui/#{Process.uid}/#{LABEL}", out: File::NULL, err: File::NULL)
    FileUtils.rm_f(FAIL_FILE)
  end

  def puma_answering?
    Net::HTTP.start(PROBE_URI.host, PROBE_URI.port, open_timeout: 4, read_timeout: 4) { |h| h.head(PROBE_URI.path) }
    true
  rescue StandardError
    false
  end

  def service_loaded?
    system("launchctl", "list", LABEL, out: File::NULL, err: File::NULL)
  end
end
