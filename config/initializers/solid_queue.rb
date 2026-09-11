# frozen_string_literal: true

# Default process_alive_threshold (5 minutes) assumes a server that never
# sleeps. This app runs under launchd on a laptop that takes frequent macOS
# "Maintenance Sleep" naps throughout the day (confirmed via `pmset -g log`
# correlating sleep/wake timestamps 1:1 with SolidQueue::Processes::
# ProcessPrunedError failures, e.g. 2026-08-25 15:30 UTC). Each nap suspends
# the worker process long enough to miss its 60s heartbeat, so the supervisor
# prunes it as dead on wake and fails whatever job it was running -- even
# though the process itself was fine. Root cause of TASK-84's 559 accumulated
# failures across every job class, not per-class application bugs.
#
# 30 minutes tolerates routine naps without meaningfully weakening real
# dead-process detection on a single-user local box (nothing here needs
# 5-minute failover).
SolidQueue.process_alive_threshold = 30.minutes
