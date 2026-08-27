---
id: TASK-112
title: 'Phase B: guided application session recorder with supervised intent'
status: In Progress
assignee:
  - '@mike'
created_date: '2026-08-27 22:17'
updated_date: '2026-08-27 22:22'
labels:
  - architecture
  - application-workflow
  - human-in-the-loop
dependencies: []
references:
  - TASK-105 (completed)
  - TASK-106 (completed)
documentation:
  - docs/adr/004-pump-track-job-application-loop.md
  - docs/architecture/pump-track.md
  - docs/architecture/panoramic-view.md
  - docs/architecture/signature-registry.md
modified_files:
  - app/controllers/guided_sessions_controller.rb
  - app/models/guided_session.rb
  - app/views/guided_sessions/new.html.erb
  - app/views/guided_sessions/show.html.erb
  - config/routes.rb
  - db/migrate/20260827213000_create_guided_sessions.rb
  - spec/requests/guided_sessions_spec.rb
priority: high
type: feature
ordinal: 118000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Build the supervised real-browser workflow that starts from a pasted job-posting URL and records a complete posting-to-application session. The session is a pump-track lap: Intake, Resolution, Response Construction, and Reorientation. Record meaningful page transitions, field decisions, handoffs, state changes, reversibility, required/optional/recommended distinctions, and explicit approval or denial at irreversible actions. Preserve Mike's intent annotations and enough provenance to review, resume, and later automate deterministic portions while keeping human veto at ambiguity and submission boundaries.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A localhost entry flow accepts a copied job-posting URL and starts a durable guided session against a supported provider.
- [ ] #2 A real Chrome-extension run records the posting, application phases, page transitions, meaningful field actions, and provider signatures into a reviewable session timeline.
- [ ] #3 The actor can annotate intent and classify actions as required, optional, recommended, reversible, irreversible, or approval-gated.
- [ ] #4 Irreversible actions, especially final application submission, require explicit Mike approval; no clean run auto-promotes or auto-submits.
- [ ] #5 A later run can replay deterministic steps while pausing for Mike at unknown, ambiguous, or approval-gated transitions.
- [ ] #6 The recorded session is visible in the local app and can be compared with the provider Reference Scenario.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Map existing extension capture, Scenario, and application-status seams; classify the first vertical slice.
2. Add a durable guided-session record that starts from a copied posting URL and carries the pump-track phase.
3. Add explicit intent/action metadata and approval-gated transitions without auto-submit behavior.
4. Surface the session state in the local app and leave provider-specific actions behind the existing extension seam.
5. Add focused tests, dogfood the sandbox flow, and commit without pushing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Prepared to implement the first Phase B vertical slice. Domain constraints: pump-track phases are stable; intent, reversibility, optionality, and approval are recorded facts; deterministic automation is bounded and final submission remains explicitly human-approved.
<!-- SECTION:NOTES:END -->

## Comments

<!-- COMMENTS:BEGIN -->
created: 2026-08-27 22:22
---
Implemented the first vertical slice: GuidedSession now accepts a copied HTTP(S) posting URL, persists provider host plus Intake/active state, and presents the supervised next move at a durable session URL. Added request coverage and local migration. The extension/provider event recorder remains the next slice; no provider submission or autonomous action is introduced.
---
<!-- COMMENTS:END -->
