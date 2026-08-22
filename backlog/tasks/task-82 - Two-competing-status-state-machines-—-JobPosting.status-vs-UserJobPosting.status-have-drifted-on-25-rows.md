---
id: TASK-82
title: >-
  Two competing status state machines — JobPosting.status vs
  UserJobPosting.status have drifted on 25 rows
status: To Do
assignee: []
created_date: '2026-08-22 15:39'
labels: []
dependencies: []
priority: high
type: bug
ordinal: 95000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`JobPosting` and `UserJobPosting` both have a `status` column, both have an AASM machine, and the state names overlap. Different writers target different models:

- **`bin/wwwr transition <id> <event>`** → writes `JobPosting.status` (states: none, favorited, applied, interview, offered, archived, **ignored, purged, expired**).
- **Web UI, Chrome extension, `UserJobPosting#record_status_event!`** → write `UserJobPosting.status` (states: none, favorited, applied, interview, offered, archived).

They are never reconciled, and **25 rows currently disagree**. Examples:

| Posting | JobPosting.status | UserJobPosting.status |
|---|---|---|
| #2125 Lead SWE, Front Office AI | ignored | **applied** |
| #1821 Rails / React Lead Engineer | purged | favorited |
| #5033 Principal Engineer | none | favorited |
| #2117 Remote Sr/Staff Engineer | archived | favorited |

#2125 is the worst shape: applied to, and simultaneously marked ignored.

## Why it matters beyond tidiness
`bin/wwwr transition` **also creates a `PipelineStep`** recording the event, so the audit trail says the user pipeline advanced while `UserJobPosting.status` never moved. Any funnel metric is therefore unreliable depending on which model it reads:

- by `UserJobPosting`: 2 applied, 144 untriaged
- by `JobPosting`: 4 applied, 452 ignored, 407 none

This is foundational for the strategic-decision system Mike wants built over the posting corpus. "Have I applied to this?" currently has two answers.

## Shape
Pick one owner. `UserJobPosting` is the semantically correct home for *the user's relationship to a posting*; `JobPosting.status` conflates that with posting lifecycle (expired/purged are properties of the posting, not of Mike's pipeline). Likely: split lifecycle (expired/purged) onto JobPosting, move all pipeline states to UserJobPosting, and make `bin/wwwr transition` write through `record_status_event!` like every other caller.

Reconcile the existing 25 before or during.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 One model owns the user's pipeline state; the other owns posting lifecycle only
- [ ] #2 bin/wwwr transition writes through the same path as the UI and extension
- [ ] #3 The 25 drifted rows are reconciled, #2125 (applied+ignored) explicitly resolved
- [ ] #4 A PipelineStep is never created for a transition that did not actually change pipeline state
- [ ] #5 Funnel counts return the same answer regardless of which model is queried
<!-- AC:END -->
