---
id: TASK-128
title: >-
  Harness-legibility surfaces: per-posting badge, per-company counts,
  guided-sessions index
status: To Do
assignee: []
created_date: '2026-08-29 20:37'
updated_date: '2026-08-29 20:45'
labels:
  - application-capture-datalake
  - 'wayfinder-map:doc-7'
dependencies:
  - TASK-112
  - TASK-129
references:
  - >-
    backlog/docs/wayfinder/doc-7 -
    Wayfinder-map-link-to-application-capture-and-the-datalake.md
  - >-
    backlog/tasks/task-125 -
    Wayfinder-decision-wwworkremote.localhost-harness-legibility-surfaces.md
  - docs/architecture/panoramic-view.md
priority: medium
type: feature
ordinal: 144000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implements the decision recorded on TASK-125 (wayfinder map doc-7). Makes the guided-session / datalake subsystem ("the harness") visible from the main wwworkremote.localhost UI.

Depends on the map's entry seam: `GuidedSession belongs_to :user_job_posting` (nullable) + the "Start supervised application" affordance on `job_postings/show`. If that seam is not yet its own task when this is picked up, it is a prerequisite slice of this task.

Advisory-only, read-only surfaces — nothing here changes `UserJobPosting` AASM state or triggers provider action.

## Harness state (shared helper)

One helper computes a posting's furthest-reached harness state from the `GuidedSession`s linked to its `UserJobPosting` (no new column):
- none — no linked `GuidedSession` (render nothing)
- in_progress — latest linked session `status` in `active` / `paused`
- recorded — a linked session with `status = "completed"` and `scenario_id` present
- compared — that session has >= 1 `ReferenceComparison`

"Processed through the harness" (the per-company count unit) = a `UserJobPosting` with >= 1 `GuidedSession` at `status = "completed"`. Same definition wherever the number appears.

## Scope

- `job_postings/show`: a small badge alongside the existing title badges showing furthest state; the existing "Start supervised application" affordance becomes an aside card showing state, linked session(s), last activity, `[View session]` + `[Start another]`.
- `companies/show`: a stat block ("N supervised applications - M recorded sessions") using the shared definition; each posting in that page's postings list carries the same badge.
- Guided sessions index: `GET /guided_sessions` (add `:index` to the existing route), linked from the Admin/Tools menu group in `app/views/layouts/application.html.erb` — NOT a new primary nav item. Columns: posting, company, purpose, state, last activity.
- `guided_sessions#show`: back-links to the posting and company (via the new `belongs_to :user_job_posting`).
- Panoramic View doc: update `docs/architecture/panoramic-view.md` so the planned "View full trace" link resolves to `guided_sessions#show` for guided runs (not a separate page).

## Out of scope

- Automation-readiness rollups on these surfaces (TASK-127 owns readiness UI).
- Dashboard tiles / global aggregates.
- The `Datalake::Bundle` trace detail inside `guided_sessions#show` (TASK-123 / later).
- Building the entry seam if it becomes its own separate task.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A shared helper returns a posting's furthest harness state (none / in_progress / recorded / compared) from the GuidedSessions linked to its UserJobPosting, with a spec covering each transition and the none case
- [ ] #2 job_postings/show renders a harness-state badge with the existing title badges when state is not none, and the 'Start supervised application' affordance is an aside card showing state + linked session link(s) + last activity + 'Start another'
- [ ] #3 companies/show shows 'N supervised applications - M recorded sessions' where N = distinct UserJobPostings for that company with >=1 completed GuidedSession, and each posting row in the list carries the same badge
- [ ] #4 The 'processed through the harness' count uses one definition (UserJobPosting with >=1 completed GuidedSession) in the helper, reused by both the company stat and any other caller; a spec asserts an in-progress-only posting is excluded from the count
- [ ] #5 GET /guided_sessions lists recent sessions (posting, company, purpose, state, last activity) and is linked from the Admin/Tools menu group in the layout, not primary nav
- [ ] #6 guided_sessions#show back-links to its posting and company when user_job_posting is present, and degrades cleanly when it is nil
- [ ] #7 docs/architecture/panoramic-view.md updated: 'View full trace' for a guided run points at guided_sessions#show
- [ ] #8 No surface added here writes UserJobPosting/JobPosting state or calls a provider; request specs confirm all new endpoints are read-only
- [ ] #9 brakeman + rubocop -a clean; extension/manifest.json untouched (no extension change in this task)
<!-- AC:END -->
