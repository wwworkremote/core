---
id: TASK-82
title: >-
  Two competing status state machines — JobPosting.status vs
  UserJobPosting.status have drifted on 25 rows
status: In Progress
assignee:
  - claude
created_date: '2026-08-22 15:39'
updated_date: '2026-08-26 23:13'
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

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Research findings (2026-08-26)

Full writer inventory across the codebase:

**Already dual-writing (a prior session's stopgap, same comment repeated verbatim at each site: "Same two-machine write as every importer/every session — JobPosting and UserJobPosting drift when only one is moved (TASK-82)"):**
- `lib/wwwr/cli.rb#perform_transition` (bin/wwwr transition)
- `app/services/applications/indeed_row_importer.rb#advance`
- `app/services/applications/greenhouse_row_importer.rb#advance`
- `app/controllers/job_postings_controller.rb#favorite_for_current_user`

All four call `posting.<event>!` (JobPosting AASM) *and* `record_status_event!` (UserJobPosting AASM) together. This keeps the two in sync going forward for these four call sites only — it is not AC #1's "one model owns pipeline state," it's a stopgap that stops new drift at these specific sites.

**JobPosting-only, and correctly so (posting-lifecycle, not user-pipeline — no change needed here):**
- `app/jobs/job_lifecycle/expiry_sweep_job.rb` — `expire!`
- `app/models/concerns/job_posting/geocoding.rb#enforce_commute_zone` — `ignore!`
- `app/controllers/admin/job_postings_controller.rb#purge` / `#restore` — `purge!` / `restore!`

**UserJobPosting-only, correctly so (already routes through record_status_event!):**
- `app/controllers/user_job_postings_controller.rb` ("Your Activity" section on job_postings/show)
- `app/controllers/api/v0/application_statuses_controller.rb` (Chrome extension)

**The one remaining, actively-drifting writer — the real gap:**
- `app/controllers/admin/pipeline_steps_controller.rb#apply_status_event` — writes `@job_posting.public_send(bang)` (favorite!/apply!/interview!/offer!/archive!/ignore!/expire! on JobPosting) with **no dual-write at all**. This backs BOTH the triage queue (job_posting_triage/show.html.erb — this session's Skip Tax work) and the "Application Status" sidebar card on job_postings/show.html.erb (TASK-64) — the two highest-traffic interaction points in the app. Every triage decision and every Application Status pill click today still causes new drift, on the busiest surfaces, right now.

## Proposed phasing

Given the size (schema change + data backfill + every JobPosting.status-reading call site), this needs to be staged rather than done as one change. Presenting for approval before writing code, per the material-decision review rule.

**Phase 1 — stop the active bleeding (small, low-risk, consistent with the existing stopgap pattern):**
Add the same dual-write to `Admin::PipelineStepsController#apply_status_event` that the four other call sites already use, for the pipeline-state events only (favorite/apply/interview/offer/archive — not ignore/expire, which stay JobPosting-only like every other site). One or two lines, following an established pattern, not a new one.

**Phase 2 — reconcile the 25 existing drifted rows (AC #3):**
Needs the actual 25 rows pulled and a reconciliation rule decided (naive "most recent wins" is wrong here since JobPosting alone holds ignored/purged/expired, which aren't blind overwrites) — will present the data and a proposed rule before writing any reconciliation script, since this mutates real records including #2125 (applied+ignored).

**Phase 3 — the actual architectural fix (AC #1, #5):**
Remove favorited/applied/interview/offered/archived from JobPosting's AASM entirely (keep only none/ignored/purged/expired), migrate every remaining JobPosting.status-reading call site (dashboards, funnel counts, bin/wwwr filters/print_postings, admin views) to read UserJobPosting instead, then delete the now-redundant dual-write plumbing from all 5 sites. Highest risk/effort of the three phases — likely warrants its own dedicated pass rather than folding into this one.

Recommending: do Phase 1 now (bounded, safe, immediately stops the worst ongoing damage), surface Phase 2's actual data before touching it, and treat Phase 3 as a separate follow-up once 1+2 are settled — rather than attempting the full schema migration in this pass.
<!-- SECTION:PLAN:END -->
