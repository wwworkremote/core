---
id: TASK-31
title: wwworkremote-ctl should detect/reap orphaned Solid Queue worker processes
status: Done
assignee: []
created_date: '2026-07-28 13:30'
updated_date: '2026-08-16 17:29'
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

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added orphan detection/reaping to bin/wwworkremote-ctl for the jobs (Solid Queue) service:

- `_sq_all_pids`: every live solid-queue-{worker,dispatcher,scheduler,fork-supervisor} PID via `ps`.
- `_sq_supervised_pids`: parses the current fork-supervisor's own `ps` command line ("supervising: X, Y, Z...") to get its real tracked children.
- `_sq_orphan_pids`: set difference -- any live Solid Queue PID that isn't the current supervisor or one of its tracked children.
- `status jobs`: warns (non-destructive) listing orphan PID + command, with a hint to restart to reap.
- `restart jobs`: after the new supervisor comes up, auto-reaps orphans (SIGTERM, 2s grace, SIGKILL fallback).

Live-verified against a real orphan already running on this machine (pid 5222, a solid-queue-worker running since a much earlier session, invisible to `status` before this change). `status jobs` correctly flagged only that one PID, not any of the 7 legitimately-supervised children. `restart jobs` reaped it -- and also caught a SECOND, freshly-created straggler (a worker from the old supervisor's tree that `zdots_svc_launchd_stop` didn't cleanly kill before returning), which is exactly the race this task describes happening live in the same test run. Post-restart tree confirmed clean: new supervisor with exactly its 7 children, zero orphans.

One real bug found and fixed during live testing: the `known` PID set was built via unquoted-in-string command substitution, which preserves literal newlines instead of spaces, so the containment check (`*" $pid "*`) never matched any legitimate child -- every supervised process was being flagged as an orphan. Fixed with `tr '\n' ' '`. Also fixed a `set -e` footgun: `[[ "$SVC_NAME" == "jobs" ]] && _sq_warn_orphans ...` exits nonzero (and kills the whole script under `set -e`) whenever the condition is false, which broke `status all`/`status web`; converted to a proper `if` block.

shellcheck clean (one info-level SC2009 suggestion, not actionable). bin/** is excluded from the ShellCheck pre-commit hook, but ran it manually anyway.
<!-- SECTION:FINAL_SUMMARY:END -->
