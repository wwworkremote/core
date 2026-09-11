---
id: TASK-147.1
title: >-
  Interview process tracking — multi-round InterviewSession sequence + action
  items
status: In Progress
assignee: []
created_date: '2026-09-03 15:42'
updated_date: '2026-09-03 15:53'
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
- [x] #1 InterviewSession has position:integer, outcome:string, interviewers:string columns via migration; schema annotations regenerated
- [x] #2 scheduled_at is no longer unconditionally required — an InterviewSession with outcome 'pending' and no scheduled_at is valid; a held/completed round still requires it
- [x] #3 InterviewProcess.seed_default(user_job_posting, template:) creates an ordered set of InterviewSession rows for :standard_senior, :compressed, and :staff templates; templates live in a frozen constant, not a DB table
- [x] #4 seed_default is idempotent-safe: calling it when sessions already exist for that posting does not duplicate rows (raises or no-ops, documented)
- [x] #5 Homepage Interviews block shows round position/count, session type, scheduled time (or 'not scheduled'), and the next open InterviewTask for that posting
- [ ] #6 Per-round outcome (advanced/rejected/no_signal) is settable and, on the final round, drives UserJobPosting status/outcome consistently with the existing after_create interview hook
- [ ] #7 Posting show page renders the session list as an ordered sequence with per-round outcome and an 'add next round' affordance
- [ ] #8 Model specs cover: the three templates, the relaxed validation, seed_default idempotency, and terminal outcome -> UserJobPosting wiring
- [x] #9 Request/system spec covers the homepage Interviews block showing sequence position and next action
- [x] #10 docs/agents/domain.md (or the relevant domain doc) notes InterviewSession = round, InterviewTask = action item, and the template constant
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Steps 1-3 of the design shipped on branch `feat/homepage-pipeline-blocks` (commits 3f04454a homepage pipeline blocks, 0823bfa0 this).

DONE:
- Migration `20260903154301` adds `position:integer`, `outcome:string` (not null, default "pending"), `interviewers:string` to `interview_sessions`.
- `InterviewSession`: `OUTCOMES = %w[pending advanced rejected no_signal]`, `validates :outcome, inclusion`, `validates :scheduled_at, presence: true, unless: :pending?`, `scope :ordered` (position, scheduled_at), `#pending?`. `after_create` + `after_update if: saved_change_to_scheduled_at?` both call `advance_application_to_interview`, which no-ops unless the round has a date.
- `app/models/interview_process.rb` (plain module): `TEMPLATES` frozen constant (`:standard_senior` 7 rounds / `:compressed` 6 / `:staff` 10), `.seed_default(ujp, template:)` -> ordered unscheduled `InterviewSession` rows, no-op if the posting already has sessions for that user, raises ArgumentError on unknown template. `.in_flight_for(user)` -> `[Progress(posting, current, position, total, next_task)]`, one per posting with a pending round; `next_task` = soonest pending `InterviewTask`.
- `User has_many :interview_sessions, :interview_tasks`.
- Homepage Interviews block iterates `@interview_processes` (was `@upcoming_interviews`): "Round N of M", current round type + `notes` label, date or "Not scheduled yet", "Next: <task>" when present, "Open Prep Pack" -> `job_posting_path(job, anchor: "interview-prep")`.
- `CONTEXT.md` domain-language entries: Interview Round / Interview Task / Interview Process Template.
- Specs: `spec/models/interview_process_spec.rb` (templates, seed_default incl. idempotency + unknown template, in_flight_for), `interview_session_spec.rb` (relaxed validation, placeholder no-advance, book-date-later advances), `home_spec.rb` (sequence position renders).
- Basis (JP #7068 / UJP #268) seeded with `:compressed`; round 1 (Screening / "Recruiter screen") scheduled 2026-09-03 15:00 UTC, interviewers "Recruiter (via Beep intro)".

NOT DONE (remaining ACs #6, #7, #8-partial):
- No UI to run `seed_default` or set a round's `outcome` / `scheduled_at` -- console only right now. The posting show page still has the old flat "log session" admin form + `order(scheduled_at: :desc)` list; it needs the ordered checklist + per-round outcome control + "add next round" / "seed process from template".
- Terminal wiring: setting the final round's `outcome` to advanced/rejected does not yet move `UserJobPosting` to an `offered`/`rejected` outcome or back to `applied`. Only the scheduled-round -> `interview` advance exists.
- `interview_process_spec.rb` has no terminal-outcome test (nothing to test yet).
<!-- SECTION:NOTES:END -->

## Comments

<!-- COMMENTS:BEGIN -->
created: 2026-09-03 15:53
---
Shipped steps 1-3 (migration + InterviewProcess templates + homepage "Round N of M" block) on branch feat/homepage-pipeline-blocks, commit 0823bfa0. Remaining: posting-page checklist UI to seed a process / set round dates + outcomes (AC #7), and terminal outcome -> UserJobPosting wiring (AC #6). 41 specs green.
---
<!-- COMMENTS:END -->
