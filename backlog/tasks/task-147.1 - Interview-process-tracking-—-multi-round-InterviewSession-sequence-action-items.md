---
id: TASK-147.1
title: >-
  Interview process tracking — multi-round InterviewSession sequence + action
  items
status: In Progress
assignee: []
created_date: '2026-09-03 15:42'
labels:
  - job-search
  - interview-prep
dependencies: []
references:
  - app/models/interview_session.rb
  - app/models/interview_task.rb
  - app/models/user_job_posting.rb
  - app/controllers/home_controller.rb
  - app/views/home/index.html.erb
  - app/views/job_postings/show.html.erb
parent_task_id: TASK-147
priority: medium
type: feature
ordinal: 168000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Why

A tracked application that reaches the interview stage today collapses to a single `UserJobPosting.status = "interview"` — no notion of *which round*, *what's next*, or *how each round went*. Real SWE hiring is a multi-stage pipeline (recruiter screen → HM screen → technical → onsite loop → debrief → offer), and Mike needs to track where he is in it, per company, with a date + notes per round and a sequence to follow.

Raised 2026-09-03 while prepping the Basis interview (JP #7068). This is the concrete, buildable slice of TASK-147's question — it does NOT pre-empt the ADR; it delivers the tracking substrate the ADR will reason about (PipelineStep step types for prep/interview phases, InterviewSession ↔ prep pack ↔ posting linkage, outcome → strategy feedback).

## Durable design decision (agreed 2026-09-03)

**No new model.** The two existing models cover it:

- **`InterviewSession`** = one row per interview *round* (recruiter screen, technical, onsite, …). Already carries `scheduled_at`, `session_type`, `notes`, `feedback`, `vibe`, `interview_questions`, attached `artifacts`.
- **`InterviewTask`** = action items *between* rounds (`title`, `due_at`, `status`) — currently zero rows and no real UI.

The **sequence** is the only missing concept. Deliver it by:
1. Creating the expected `InterviewSession` rows up front, most with `scheduled_at: nil` (= "expected, not yet scheduled").
2. Adding to `InterviewSession`: `position` (int, ordering), `outcome` (`pending` / `advanced` / `rejected` / `no_signal`), `interviewers` (string).
3. Relaxing the `scheduled_at` presence validation so an unscheduled future round is valid.
4. A **plain method** (not a model / not a table) `InterviewProcess.seed_default(user_job_posting, template:)` that creates the standard rows for a chosen template. Templates = a frozen constant hash keyed `:standard_senior` / `:compressed` / `:staff` (one user — no template table).
5. Surfacing the sequence: homepage **Interviews** block shows "Round N of M · <type> · <when> · next: <task>"; the posting page's session list becomes an ordered checklist with per-round `outcome` + "add next round".
6. Terminal wiring: the last session's `outcome` drives `UserJobPosting` → `applied` (rejected early) / stays `interview` / → an `offered`/`rejected` outcome, mirroring the existing `after_create` → `record_status_event!("interview")` hook.

### Reference: the "normal" SWE hiring pipeline (templates derive from this)

| Stage | Who | Format | Advance gate |
|---|---|---|---|
| Recruiter screen | Recruiter | 25–30 min | comp / level / location fit |
| HM screen | Hiring manager | 30–45 min | HM commits a full loop |
| Technical screen | 1 IC | 60 min live **or** take-home | can code |
| Onsite loop | 3–5 people | 3–5 hrs | all rounds pass (coding ×1–2, system design ×1 for senior+, behavioral ×1) |
| Debrief | panel + HM (+ committee) | internal | consensus |
| Offer + negotiation | recruiter | calls | terms + references + background |

- `:standard_senior` = all six rows above.
- `:compressed` (mid-size / startup, e.g. Basis) = recruiter → HM → technical → onsite (2–3) → VP/founder → offer.
- `:staff` = `:standard_senior` + 2nd architecture round + cross-functional/influence round + project presentation + skip-level.

Full framing (incl. the CI/CD-pipeline analogy Mike asked for) is in the 2026-09-03 session transcript; the durable parts are captured above.

## Scope of THIS task

Steps 1–3 (migration + validation + template method + homepage wiring) ship now. Steps 5 (posting-page checklist UI) and 6 (terminal outcome wiring) are checkboxes below — deliver in the same task, not a follow-up, unless split for review size.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 InterviewSession has position:integer, outcome:string, interviewers:string columns via migration; schema annotations regenerated
- [ ] #2 scheduled_at is no longer unconditionally required — an InterviewSession with outcome 'pending' and no scheduled_at is valid; a held/completed round still requires it
- [ ] #3 InterviewProcess.seed_default(user_job_posting, template:) creates an ordered set of InterviewSession rows for :standard_senior, :compressed, and :staff templates; templates live in a frozen constant, not a DB table
- [ ] #4 seed_default is idempotent-safe: calling it when sessions already exist for that posting does not duplicate rows (raises or no-ops, documented)
- [ ] #5 Homepage Interviews block shows round position/count, session type, scheduled time (or 'not scheduled'), and the next open InterviewTask for that posting
- [ ] #6 Per-round outcome (advanced/rejected/no_signal) is settable and, on the final round, drives UserJobPosting status/outcome consistently with the existing after_create interview hook
- [ ] #7 Posting show page renders the session list as an ordered sequence with per-round outcome and an 'add next round' affordance
- [ ] #8 Model specs cover: the three templates, the relaxed validation, seed_default idempotency, and terminal outcome -> UserJobPosting wiring
- [ ] #9 Request/system spec covers the homepage Interviews block showing sequence position and next action
- [ ] #10 docs/agents/domain.md (or the relevant domain doc) notes InterviewSession = round, InterviewTask = action item, and the template constant
<!-- AC:END -->
