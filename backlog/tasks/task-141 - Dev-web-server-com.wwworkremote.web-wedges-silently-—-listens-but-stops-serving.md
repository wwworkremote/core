---
id: TASK-141
title: >-
  Dev web server (com.wwworkremote.web) wedges silently — listens but stops
  serving
status: To Do
assignee: []
created_date: '2026-08-31 14:58'
updated_date: '2026-08-31 15:08'
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

## Comments

<!-- COMMENTS:BEGIN -->
author: claude (session_01WGSW36NJ)
created: 2026-08-31 15:08
---
**Diagnosis pass 1 — 2026-08-31.**

**Mitigation f540efb5 did NOT work.** With `SKIP_OTEL=1` and rdbg env removed, the server still wedged ~7 min after restart. So OTel exporter and rdbg are ruled out as the primary cause.

**Thread dump of the wedged process** (`kill -INFO <pid>`, output in `~/.local/state/wwworkremote/web.log`):
- All 5 `puma srv tp` worker threads: **idle**, waiting on `@not_empty` condvar (`thread_pool.rb:236`). Not stuck in app code.
- `puma srv` thread: in `IO.select` inside `handle_servers` (`server.rb:361`).
- `puma reactor`: in `NIO::Selector#select`.
- One inbound TCP connection to :31000 accepted but never dispatched to a worker.
- ActionCable `StreamEventLoop` thread present and in its own `NIO::Selector#select`.
- Also live (harmless, but noise): a `DEBUGGER__::Session@server` thread (debug gem session still activated despite env removal — source of `RUBY_DEBUG_OPEN` not yet found; not in .env, plist, launchctl env, or repo outside bin/dev), and an `sshkit` connection-pool eviction loop (kamal pulls sshkit into the web boot).

**Signature = puma stopped accepting/dispatching, app itself not deadlocked.** Classic 'the reactor/accept loop wedged' — not worker-pool exhaustion (workers were idle).

**Correlated symptom in `log/development.log`:** every 60s exactly, a malformed `GET /cable` (`HTTP_UPGRADE` and `HTTP_CONNECTION` both empty) → `Failed to upgrade to WebSocket`. Source not identified (not in bin/, crontab, extension, or context-engine). Also seen: occasional 3-4s requests (`ActiveRecord: 3110ms, 27 queries`).

**Environment factor:** Ruby **4.0.6** (bleeding edge) + `nio4r` native selectors used by BOTH puma's reactor and ActionCable's in-process event loop. A native-selector incompatibility on Ruby 4.0 is a live hypothesis and could be upstream.

**Recommended mitigation (not yet applied — needs Mike's ok):** run `com.wwworkremote.web` in puma **cluster mode** (`WEB_CONCURRENCY=1`, `OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES`) with a short `worker_timeout` (~120s) via a new `PUMA_WORKER_TIMEOUT` env knob in `config/puma.rb`. The master then SIGKILLs + respawns a wedged worker in ~2 min instead of a permanent hang. `bin/dev` stays single-mode (unaffected; keeps the 3600s timeout for breakpoints). Doesn't fix root cause but bounds the outage to ~2 min and makes the box usable for the job search. Root cause (nio4r/cable/Ruby 4.0) stays open under this task.

Manual recovery meanwhile: `launchctl kickstart -k gui/$(id -u)/com.wwworkremote.web`
---
<!-- COMMENTS:END -->
