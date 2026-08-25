---
id: TASK-84
title: Triage the 531 accumulated SolidQueue failed executions
status: To Do
assignee: []
created_date: '2026-08-24 16:46'
updated_date: '2026-08-25 17:17'
labels: []
dependencies: []
priority: medium
type: bug
ordinal: 97000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`SolidQueue::FailedExecution` has **531 rows** as of 2026-08-24. Surfaced while verifying the dev stack was healthy; nothing currently tracks it.

Concentrated in six job classes:

| Job | Failures |
|---|---|
| `EmailImportJob` | 148 |
| `JobBoards::ContentEnrichmentJob` | 87 |
| `SyncDashboardJob` | 62 |
| `JobBoards::LinkMonitorJob` | 59 |
| `HackerNews::FetchJobstoryJob` | 54 |
| `JobBoards::AnalysisJob` | 44 |

**This is accumulated, not acute** — only 2 failures in the trailing 12 hours, newest 2026-08-24 11:20 UTC. Ready and scheduled queues are both empty, so nothing is wedged right now. That is the argument for Medium rather than High, and also the reason it has gone unnoticed.

**Why it still matters:** a 531-row failure table means no one can tell a new breakage from the background noise. The next real pipeline regression will land in this pile and be invisible. The value here is restoring the signal, not the individual retries.

## Approach

Classify before retrying — the six classes almost certainly do not share a root cause. `EmailImportJob` at 148 is the obvious first pull. The `pipeline-health` skill already distinguishes code bugs from worker/infra failures and should be the entry point rather than a fresh investigation.

Expect a meaningful fraction to be unretryable historical junk (dead source URLs, postings taken down). Those should be discarded deliberately rather than retried into failing again.

## Boundaries

Do not bulk-retry all 531 blindly — `ContentEnrichmentJob` and `AnalysisJob` make LLM calls, so a mass retry has real token cost. Discarding is also destructive; sample and diagnose each class before deciding retry vs discard.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Failures are classified by root cause per job class, not just counted
- [x] #2 EmailImportJob (148) is diagnosed to a specific cause
- [ ] #3 Each class has an explicit retry-or-discard decision recorded with its reason
- [ ] #4 No blind bulk retry of the LLM-calling jobs (ContentEnrichmentJob, AnalysisJob)
- [ ] #5 FailedExecution count is reduced to a level where a new failure is visible
- [x] #6 Any code bug found is fixed or filed as its own task, not just retried around
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-08-25: pipeline-health-agent audit found 559 failed executions (up from ~531), and root-caused all 14 failing job classes to the SAME underlying cause: SolidQueue::Processes::ProcessPrunedError (11 classes) / ProcessMissingError (3 classes: SyncDashboardJob, JobBoards::AnalysisJob, JobBoards::GeocodingJob). Every failure traces to the worker process itself dying/getting reaped mid-job, not to any job's application logic -- this is a worker/infra problem (OOM? long-running job timeout? host restarts?), not 531+ separate job bugs. Next step should investigate why the `jobs` launchd service's worker process keeps dying, e.g. check bin/wwworkremote-ctl supervisor restart cadence and system resource limits, rather than triaging failures class-by-class.

2026-08-25 (later): Root-caused one level deeper. All 559 failures trace to SolidQueue::Processes::ProcessPrunedError/ProcessMissingError, and those trace to macOS "Maintenance Sleep" -- confirmed 1:1 by correlating `pmset -g log` sleep/wake timestamps against failure timestamps (sleep/wake at 2026-08-25 10:30:46-10:35:02 local = 15:30-15:35 UTC, matching a ContentEnrichmentJob failure at 15:30:50 UTC exactly). SolidQueue's default process_alive_threshold is 5 minutes; this laptop naps for maintenance sleep multiple times a day even while awake/in-use (PreventUserIdleSystemSleep assertion active), each nap long enough to miss the worker's 60s heartbeat and get pruned as dead on wake, failing whatever job it was running. Not 559 separate job bugs -- one infra mismatch (server-oriented default threshold on a laptop that sleeps).

Fix shipped: config/initializers/solid_queue.rb sets process_alive_threshold to 30 minutes, tolerating routine naps. jobs service restarted to pick it up. Resolves AC #1 (single root cause, not per-class), #2 (EmailImportJob's 148 failures are this same cause), #6 (real fix shipped, not a retry-around).

Still open: AC #3/#4/#5 -- the actual retry-or-discard triage of the 559 existing failed rows. That's a separate, deliberate pass (some are genuinely stale/dead-source-URL junk worth discarding; ContentEnrichmentJob/AnalysisJob retries cost real LLM tokens per this task's own boundaries) and shouldn't be rushed through as part of a session wrap-up. Recommend a dedicated pass sampling each of the 6 job classes before deciding retry vs. discard per class.
<!-- SECTION:NOTES:END -->
