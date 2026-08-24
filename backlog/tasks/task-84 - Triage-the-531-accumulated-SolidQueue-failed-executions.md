---
id: TASK-84
title: Triage the 531 accumulated SolidQueue failed executions
status: To Do
assignee: []
created_date: '2026-08-24 16:46'
updated_date: '2026-08-24 16:47'
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
- [ ] #1 Failures are classified by root cause per job class, not just counted
- [ ] #2 EmailImportJob (148) is diagnosed to a specific cause
- [ ] #3 Each class has an explicit retry-or-discard decision recorded with its reason
- [ ] #4 No blind bulk retry of the LLM-calling jobs (ContentEnrichmentJob, AnalysisJob)
- [ ] #5 FailedExecution count is reduced to a level where a new failure is visible
- [ ] #6 Any code bug found is fixed or filed as its own task, not just retried around
<!-- AC:END -->
