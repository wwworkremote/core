---
id: TASK-28
title: Replace foreman with launchd-backed service control (bin/wwworkremote-ctl)
status: Done
assignee: []
created_date: '2026-07-28 00:08'
updated_date: '2026-07-28 00:08'
labels: []
dependencies: []
references:
  - bin/wwworkremote-ctl
  - bin/wwworkremote-web
  - bin/wwworkremote-jobs
  - ~/.config/zsh/lib/svc-launchd.bash
priority: medium
ordinal: 27000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Root-caused a live 500/outage this session: a database.yml pool-size change (Phase 1 connection pooling work) left Solid Queue's dev worker under-provisioned (needed 7 connections, had 5), causing the jobs process to crash-loop 7,100+ times. foreman's group-kill-on-any-sibling-exit behavior (also separately triggered by the sandboxed tailwindcss:watch process exiting cleanly) then took the whole dev server down repeatedly during recovery. Replaced the foreman-managed web+jobs processes with real launchd LaunchAgents, following the same pattern zdots itself uses (~/.config/zsh/lib/svc-launchd.bash, docs/platform-service-plane.md) -- KeepAlive + a 30s ThrottleInterval means a future crash gets throttled and retried instead of spiraling, and each process is independent (one crashing doesn't take the other down). bin/dev (foreman) is left in place for interactive terminal use with the CSS watcher; the new path is for persistent background use.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 bin/wwworkremote-ctl start/stop/restart/status/logs work for web, jobs, and all
- [x] #2 Both services registered as LaunchAgents with KeepAlive + ThrottleInterval
- [x] #3 https://wwworkremote.localhost/ verified reachable (401, correct auth-gated response) after switching over
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented and verified live 2026-07-27: bin/wwworkremote-ctl start all registered com.wwworkremote.{web,jobs} as LaunchAgents, both came up clean (web pid 9606, jobs pid 9640), logs landed in ~/.local/state/wwworkremote/, and https://wwworkremote.localhost/ returned 401 (correct auth-gated response, not 500/502). Old ad hoc nohup/foreman instance from the incident was torn down first.
<!-- SECTION:NOTES:END -->
