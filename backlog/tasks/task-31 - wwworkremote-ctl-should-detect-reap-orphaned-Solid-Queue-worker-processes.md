---
id: TASK-31
title: wwworkremote-ctl should detect/reap orphaned Solid Queue worker processes
status: To Do
assignee: []
created_date: '2026-07-28 13:30'
updated_date: '2026-07-28 13:45'
labels: []
dependencies: []
priority: high
ordinal: 30000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Discovered 2026-07-28: an orphaned solid_queue-worker process (pid 56900, forked 2026-07-27 21:37:26 during the session's earlier nohup/foreman restart chaos, reparented to launchd/pid 1 when its supervisor died) kept running silently for ~11 hours, invisible to every subsequent bin/wwworkremote-ctl restart jobs -- because launchctl bootstrap/kickstart only tracks the PID of the process it directly started, not any orphaned children/forks left behind by a prior non-launchd-managed run. Because Solid Queue's ForkSupervisor uses fork() (not exec()), the orphan kept running the exact in-memory Ruby code loaded at fork time, silently bypassing the TASK-26 interstitial-detection fix that was already live everywhere else -- produced 3 more fake JobPosting rows over the following hours before being found via a created_at anomaly and killed manually (ps aux | grep solid-queue, matched against the supervisor's own 'supervising: PID list' to find the non-member). Add an orphan check to bin/wwworkremote-ctl status/restart: compare live solid-queue-worker/dispatcher/scheduler PIDs (ps) against the current supervisor's tracked children, warn or auto-reap anything running Solid Queue that isn't in that tree.
<!-- SECTION:DESCRIPTION:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Confirmed systemic, not a one-off: a SECOND orphan (pid 89654, from an earlier today restart) was found still running during a completely separate investigation (verifying the TASK-27 gzip/OTel fork-safety fix), unrelated to the original 56900 incident. Every bin/wwworkremote-ctl restart jobs so far has left at least one orphan behind -- likely launchctl bootout/SIGTERM to the top-level fork-supervisor process not reliably propagating to its already-forked children before the supervisor itself dies, a race rather than a rare edge case. Bumping to high priority.
<!-- SECTION:NOTES:END -->
