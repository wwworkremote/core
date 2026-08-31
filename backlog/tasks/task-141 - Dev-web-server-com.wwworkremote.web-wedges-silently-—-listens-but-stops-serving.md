---
id: TASK-141
title: >-
  Dev web server (com.wwworkremote.web) wedges silently — listens but stops
  serving
status: To Do
assignee: []
created_date: '2026-08-31 14:58'
labels:
  - infra
  - dev-env
dependencies: []
priority: high
type: bug
ordinal: 157000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Symptom

The launchd-managed dev web service `com.wwworkremote.web` (runs `bin/wwworkremote-web` -> `bundle exec puma -C config/puma.rb`, port 31000) periodically stops answering HTTP entirely: the process is alive and holds the listen socket, but every request hangs (curl `000` after timeout, browser "failed to fetch", extension side panel errors). Because the process never exits, launchd `KeepAlive` does not restart it. Observed 2026-08-31: fine right after restart, wedged again within ~15-20 min under LLM-chat / Turbo-broadcast load. `~/.local/state/wwworkremote/web.log` shows only clean startup banners between restarts — no crash, no error. Rails request log (`log/development.log`) is dominated by SolidQueue polling + an active `llm_chats` stream at the wedge time.

Fix is `launchctl kickstart -k gui/$(id -u)/com.wwworkremote.web`.

## Mitigation already applied (commit pending)

`bin/wwworkremote-web` now exports `SKIP_OTEL=1` and drops `RUBY_DEBUG_OPEN`/`RUBY_DEBUG_LAZY` (non-interactive service — a stray `debugger` would suspend the process forever; the OTLP exporter background thread + fork-safety mutexes are a known hang surface). This is a shot in the dark, not a confirmed root cause — needs verification that the wedge stops recurring.

## Suspects (unconfirmed)

1. **rdbg remote-debug hang** — `RUBY_DEBUG_OPEN=true` + any `debugger`/`binding.break` reached at runtime suspends the whole process waiting for a client that never connects. No stray calls found in app/lib/config, but a gem could. (removed in mitigation)
2. **OTel OTLP exporter** — BatchSpanProcessor background thread deadlock on the fork-safety mutexes described in `config/initializers/opentelemetry.rb`; or export blocking when the collector/OpenObserve is down (Codex handoff 2026-08-31 noted OpenObserve down). (disabled in mitigation)
3. **Puma thread-pool exhaustion** — dev puma is single-mode, `threads 5`. Several browser tabs each holding a `solid_cable` ActionCable connection for Turbo Streams (dashboard, llm_chats, job postings) + a couple slow requests could consume all 5 threads. If mitigation 1+2 don't fix it, bump `RAILS_MAX_THREADS` for the service and/or move cable to its own process.

## Acceptance

- [ ] Server runs a full work session (several hours, real dogfooding load) without wedging, OR
- [ ] Root cause identified and fixed at the source (not just env flags), with the wedge no longer reproducible
- [ ] `bin/wwworkremote-web` mitigation kept or reverted based on the finding, comment updated

## Notes

- Service plists: `~/Library/LaunchAgents/com.wwworkremote.{web,jobs}.plist` (user LaunchAgents, `runatload` + `keepalive`). Registered by `bin/wwworkremote-ctl`.
- `com.wwworkremote.jobs` (SolidQueue supervisor, PID stable since 08-27) has NOT shown this problem — web only.
<!-- SECTION:DESCRIPTION:END -->
