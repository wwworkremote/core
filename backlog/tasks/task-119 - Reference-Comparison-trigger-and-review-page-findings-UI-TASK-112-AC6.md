---
id: TASK-119
title: Reference Comparison trigger and review-page findings UI (TASK-112 AC#6)
status: To Do
assignee: []
created_date: '2026-08-29 00:21'
labels:
  - architecture
  - application-workflow
  - reference-comparison
  - human-in-the-loop
dependencies:
  - TASK-116
  - TASK-117
  - TASK-118
documentation:
  - docs/adr/009-reference-comparison-drift-and-coverage.md
  - docs/architecture/guided-session-flow.md
  - docs/architecture/signature-registry.md
  - app/models/guided_session.rb
  - app/views/guided_sessions/show.html.erb
priority: high
type: feature
ordinal: 135000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Per ADR 009. Wires the comparison engine (TASK-116) and records (TASK-117) to the guided session lifecycle and review page, and closes TASK-112 AC#6 ('The recorded session is visible in the local app and can be compared with the provider Reference Scenario'). Depends explicitly on TASK-116 (engine), TASK-117 (records) and TASK-118 (a usable structural reference) — its acceptance exercises all three seams.

Scope:
- Automatic trigger: when a GuidedSession first transitions to completed, run a ReferenceComparison. The trigger is idempotent for that transition — retries or repeated transitions must not create duplicate 'automatic' runs.
- Manual trigger: a 'Compare to Reference' action on the guided session review page creates a new ReferenceComparison run every time it is invoked.
- The comparison is advisory and presentational only. It must never authorize, block, advance, or submit an application, and must not change the session phase, status, or playback position. Mirror the existing playback-cursor 'viewing not authorization' separation.
- Review page presentation:
  - the coverage phase/step map (reached / not reached / not applicable), not just a percentage; 'unavailable' shown as such
  - the drift findings for the run, each with its dimension and locator
  - for each finding, the disposition control with the five values, showing any carried-forward suggestion (and its source) as a default that still requires explicit confirmation
  - prior runs for the session remain viewable (immutable history)
- If a real provider is not involved and no reference exists for the provider, the page states that plainly rather than erroring.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A GuidedSession transitioning to completed for the first time automatically creates exactly one ReferenceComparison; a repeated or retried completed transition creates no additional automatic run (idempotent) — proven by a spec
- [ ] #2 The 'Compare to Reference' review-page action creates a new immutable ReferenceComparison run on each invocation — proven by a spec
- [ ] #3 Neither the automatic nor the manual path changes session phase, status, playback position, or authorizes/advances/submits an application — proven by a spec asserting session state is unchanged across a comparison
- [ ] #4 The review page renders the coverage phase/step map with reached / not reached / not applicable states and shows 'unavailable' when there are zero applicable checkpoints
- [ ] #5 The review page lists the run's drift findings with dimension and locator, and offers a disposition control with the five values per finding
- [ ] #6 A carried-forward disposition appears as a labelled suggestion with its source, and the finding is not considered dispositioned until the reviewer confirms
- [ ] #7 Prior comparison runs for the session remain viewable as immutable history
- [ ] #8 When no Reference Scenario exists for the provider, the page says so instead of raising
- [ ] #9 TASK-112 AC#6 is checked; guided-session request spec coverage for the trigger, the advisory-only guarantee, and the findings/disposition rendering
<!-- AC:END -->
