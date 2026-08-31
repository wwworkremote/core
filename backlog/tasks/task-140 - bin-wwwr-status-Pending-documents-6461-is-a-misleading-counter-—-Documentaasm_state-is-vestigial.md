---
id: TASK-140
title: >-
  bin/wwwr status "Pending documents: 6461" is a misleading counter —
  Document#aasm_state is vestigial
status: To Do
assignee: []
created_date: '2026-08-31 13:17'
labels:
  - observability
  - cleanup
dependencies: []
references:
  - lib/wwwr/cli.rb
  - >-
    backlog/tasks/task-84 -
    Triage-the-531-accumulated-SolidQueue-failed-executions.md
priority: low
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
