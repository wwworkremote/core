---
id: TASK-125
title: 'Wayfinder decision: wwworkremote.localhost harness-legibility surfaces'
status: Done
assignee:
  - '@claude'
created_date: '2026-08-29 17:24'
updated_date: '2026-08-29 20:37'
labels:
  - 'wayfinder:grilling'
  - application-capture-datalake
  - 'wayfinder-map:doc-7'
dependencies: []
references:
  - >-
    backlog/docs/wayfinder/doc-7 -
    Wayfinder-map-link-to-application-capture-and-the-datalake.md
  - docs/architecture/panoramic-view.md
  - app/views/job_postings/show.html.erb
ordinal: 141000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Decision ticket for wayfinder map doc-7 (backlog/docs/wayfinder/doc-7). Grilling type (HITL) — resolve with Mike via grilling + domain-modeling. Unblocked (frontier). Aligns with the "expose context legibly" and "power-user tool" product principles.

## Question

What signals and navigation make the harness visible from the main wwworkremote.localhost UI?

Mike's stated need: from the main user UI he wants to see how many applications have been processed through the harness for a company, a job posting must clearly show it has been processed through the harness, there must be clear signals, and the ability to navigate back into this system from the main UI.

Open for this ticket:
- The per-posting signal on `job_postings/show` — a badge? a status chip in the existing pipeline timeline? What states does it distinguish (never touched / guided session in progress / session completed / compared against reference / application submitted)?
- Per-company aggregate — where does "N applications processed through the harness for this company" live (a company show page? the job posting's company section? the dashboard)? Does "processed" count guided sessions, materialized scenarios, or submitted applications — and is the definition the same everywhere it appears?
- Navigation affordances — entry (the "Start supervised application" button already decided in the map) and return (from a guided session / datalake view back to the posting and the campaign). Is there a top-level nav entry for the guided-session/datalake subsystem, or is it always reached contextually from a posting?
- The relationship to Panoramic View's planned "View full trace" link from `job_postings/show` — same entry point, or distinct?
- Whether any of these surfaces show automation-readiness rollups (from TASK-124) or that is deferred.

Output: the surface + signal + navigation decisions recorded on the map; implementation TASK-* created if the shape is clear enough to hand off.
<!-- SECTION:DESCRIPTION:END -->

## Comments

<!-- COMMENTS:BEGIN -->
author: @claude (wayfinder)
created: 2026-08-29 20:37
---
## Resolution (wayfinder doc-7, 1 grilling round)

All four surfaces resolved; readiness rollups deferred. Implementation is **TASK-128**.

### Per-posting signal (`job_postings/show`)
**Title badge + aside card.** A small status badge sits with the existing title badges (pipeline status, lead/extension). The already-decided "Start supervised application" affordance becomes a small card in the aside showing state + links.

States, derived from `GuidedSession` for the posting's `UserJobPosting` (no new column):
| State | Derivation |
|---|---|
| _(none)_ — no badge | no `GuidedSession` linked |
| In progress | latest linked session `status` in `active` / `paused` |
| Recorded | session `status = completed` and `scenario_id` present |
| Compared | that session has ≥1 `ReferenceComparison` |
Badge shows the furthest state reached. Card lists the session(s), last activity date, `[View session]` + `[Start another]`.

### Per-company aggregate (`companies/show`)
**Company-show stat block + posting-list marks.** Stat block: “N supervised applications · M recorded sessions”. Each posting in that page’s list carries the same per-posting badge.

**“Processed” is defined once, used everywhere:** a `UserJobPosting` with ≥1 `GuidedSession` whose `status = completed` (Scenario materialized). “Recorded sessions” = count of those sessions. “In progress” postings are shown with the in-progress badge but are **not** in the processed count. No dashboard tile in this scope.

### Navigation
**Contextual entry + a list view under an existing menu; `guided_sessions#show` is the canonical per-run view.**
- Entry: the aside card on `job_postings/show` (uses the map’s “Start supervised application” seam).
- A **“Guided sessions” index** (`GET /guided_sessions`) reachable from an existing menu group (Admin/Tools), **not** a new primary nav item — respects the “power-user tool, don’t add chrome” principle. Lists recent sessions with posting, company, purpose, state.
- Return: every `guided_sessions#show` back-links to its posting and company (needs the map’s `GuidedSession belongs_to :user_job_posting` seam).
- **Panoramic View alignment:** the planned “View full trace” link on `job_postings/show` points at `guided_sessions#show` for guided runs — not a separate page. `guided_sessions#show` grows the trace/datalake detail over time (`Datalake::Bundle` read side, TASK-123). One canonical run view, entered two ways.

### Readiness rollups — deferred
These surfaces show capture/comparison state only. Readiness classes and eval scores stay in the archetype review UI (TASK-127). Revisit only if Mike asks for a company-level answer-readiness summary later.

### Glossary (for spec-lock)
Coin **Harness** (the guided-session + signature-registry + datalake subsystem, as the user-facing name) and **Processed through the harness** (the definition above) in `CONTEXT.md` when the ADR is written.
---
<!-- COMMENTS:END -->
