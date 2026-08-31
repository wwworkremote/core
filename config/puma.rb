# frozen_string_literal: true

max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count)

threads min_threads_count, max_threads_count

# Dev default stays 3600 so a breakpoint under `bin/dev` isn't reaped. The
# launchd service (bin/wwworkremote-web) overrides PUMA_WORKER_TIMEOUT to a
# short value so the master kills + respawns a wedged worker instead of a
# permanent silent hang -- see TASK-141.
worker_timeout Integer(ENV.fetch("PUMA_WORKER_TIMEOUT", 3600)) if ENV.fetch("RAILS_ENV", "development") == "development"

port ENV.fetch("PORT", 31_000)

environment ENV.fetch("RAILS_ENV", "development")

pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

workers ENV.fetch("WEB_CONCURRENCY") { ENV.fetch("RAILS_ENV", "development") == "development" ? 0 : 2 }

# bin/wwworkremote-web runs 1 worker on purpose -- it wants the master process
# to supervise and reap a wedged worker (TASK-141), not for throughput.
silence_single_worker_warning

preload_app!

plugin :tmp_restart
