---
id: TASK-140
title: >-
  JobBoards::Syncer starves on an unordered LIMIT — the nil-document backlog is
  real, not just a bad counter
status: To Do
assignee: []
created_date: '2026-08-31 13:17'
updated_date: '2026-09-03 04:00'
labels:
  - observability
  - cleanup
dependencies: []
references:
  - lib/wwwr/cli.rb
  - >-
    backlog/tasks/task-84 -
    Triage-the-531-accumulated-SolidQueue-failed-executions.md
priority: medium
type: chore
ordinal: 156000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`bin/wwwr status` reports "Pending documents: <n>" via `lib/wwwr/cli.rb#pending_documents_count` = `JobBoards::Document.where(aasm_state: ["pending", nil]).count`. As of 2026-08-31 that's 6461 of 12039 Document rows — making the pipeline look badly backed up.

It isn't. Verified: `JobBoards::Document` has **no AASM defined** (`.aasm.events` raises) — `aasm_state` is a plain string column nothing maintains. 5578 rows got set to `"processed"` by something; the other 6461 sit at `nil` forever (span 07-30..08-31, +824 in the last 7d) and nothing will ever transition them. Meanwhile enrichment genuinely works: 20/20 sampled recent untriaged postings have full enriched content, ~627 postings enriched in the last 7d, 1460 LLM calls in 7d.

So the counter measures a dead column, not a real queue. It's noise that hides real signal (the same argument as TASK-84 for the failed-execution pile).

Options: drop the line from `bin/wwwr status`; or repoint it at something real (postings awaiting enrichment / Documents created in the last N days still `nil`); or remove the vestigial `aasm_state` column + `Document` state cruft if `Document` itself is still used. Decide which during the task.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 bin/wwwr status no longer reports a number that looks like a backlog when there is none
- [ ] #2 Whatever it reports (if anything) reflects real pending work, or the line is removed with a note why
- [ ] #3 If JobBoards::Document / its aasm_state column is dead weight, it is removed or documented as retained-for-reason
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-09-02 (session 4 /pipeline-health) -- sharpened diagnosis. The nil-doc backlog is NOT purely cosmetic. JobBoards::Syncer#fetch_pending_docs does `JobBoards::Document.where(aasm_state: ["pending", nil]).limit(10)` with **no ORDER BY**. Postgres returns heap order -> effectively the same ~10 oldest rows every run. The oldest 10 (created 07-30..08-17) fail conversion (QualityFilter / AttributeMapper / validation) and handle_save_failure? logs + returns false WITHOUT marking the doc processed -- so they are re-selected forever. SyncDashboardJob runs hourly with limit 10 and can never reach doc #11.

Live numbers 2026-09-02: 6831 nil docs (oldest 2026-07-30, +157 in 24h, +806 in 7d). processed docs updated in last 6h = 0; in last 24h = 36 -- which exactly matches the 36 JobPostings created in 24h, while intake is 157/day. So the fetcher->Document->Syncer path converts ~36/day against ~157/day intake and falls behind ~120/day (7d delta 806 confirms). The ~36/day that DO convert are likely poison rows rotating out of the top-10 as vacuum/updates shuffle heap order.

So TASK-140's premise 'nothing will ever transition them' is close but the mechanism is a starving unordered LIMIT, and the effect is a throughput collapse, not just a misleading number. Enrichment downstream is fine (postings that get created get enriched).

Fix is a design call (why the task says 'decide during the task'): (a) order(created_at: :asc) + a terminal 'failed'/'rejected' state so un-convertible docs leave the working set; (b) raise the limit 10 -> ~500 so a run churns the whole backlog regardless of order; (c) a last_attempted_at cursor. Likely (a)+(b). Needs a characterization spec reproducing the starvation before touching the Syncer. Also still resolve the vestigial-column / bin/wwwr status counter question.
<!-- SECTION:NOTES:END -->
