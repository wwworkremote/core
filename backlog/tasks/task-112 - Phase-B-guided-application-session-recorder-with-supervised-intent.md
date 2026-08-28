---
id: TASK-112
title: 'Phase B: guided application session recorder with supervised intent'
status: In Progress
assignee:
  - '@mike'
created_date: '2026-08-27 22:17'
updated_date: '2026-08-28 22:52'
labels:
  - architecture
  - application-workflow
  - human-in-the-loop
dependencies: []
references:
  - TASK-105 (completed)
  - TASK-106 (completed)
  - TASK-113
documentation:
  - docs/adr/004-pump-track-job-application-loop.md
  - docs/architecture/pump-track.md
  - docs/architecture/panoramic-view.md
  - docs/architecture/signature-registry.md
  - docs/architecture/guided-session-flow.md
  - docs/adr/006-bpmn-lite-guided-session-validation.md
modified_files:
  - app/models/guided_session.rb
  - app/views/guided_sessions/show.html.erb
  - >-
    backlog/tasks/task-112 -
    Phase-B-guided-application-session-recorder-with-supervised-intent.md
  - docs/architecture/guided-session-flow.md
  - extension/content.js
  - extension/manifest.json
  - spec/requests/guided_sessions_spec.rb
  - spec/requests/api/guided_session_events_spec.rb
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
- [x] #1 A localhost entry flow accepts a copied job-posting URL and starts a durable guided session against a supported provider.
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

created: 2026-08-27 23:22
---
Implemented the next vertical slice: GuidedSessionEvent persists meaningful timeline transitions with pump-track phase, intent, requirement classification, reversibility, approval state, page URL, and evidence. Added a local-only tokenized API endpoint for extension correlation and rendered events in the guided-session review page. Focused suite: 8 examples, 0 failures; targeted RuboCop clean. No autonomous provider action or submission was added.
---

created: 2026-08-27 23:24
---
Connected the local unpacked Chrome extension to the guided-session event seam. An explicit guided_session_token URL parameter records a page_arrived event with page URL/title/provider evidence; ordinary browsing is unchanged and non-local/Web Store builds are excluded by the existing IS_LOCAL_BUILD gate. Extension lint passes.
---

created: 2026-08-27 23:26
---
Dogfood check: localhost guided session #1 was created successfully and the real Chrome extension overlay loaded on the sandbox posting. The installed unpacked extension is still the prior bundle, so no page_arrived event appeared after navigation/reload; reload the extension from chrome://extensions before the next browser pass. Source and all implementation changes are committed through e8f99ae9.
---

created: 2026-08-27 23:30
---
Verified end to end after reloading Chrome extension v1.26.0: opening the tokenized sandbox posting produced the page_arrived event, and guided session #1 rendered it with intent plus recommended/reversible/not-required classifications. This validates the first real Chrome correlation checkpoint; application-phase transitions and approval-gated actions remain next.
---

created: 2026-08-27 23:37
---
Added the canonical BPMN-lite Mermaid validation scheme in docs/architecture/guided-session-flow.md and ADR 006. It now shows the four pump-track phases, User Tasks, Service Tasks, gateways, intermediate timeline events, approval interruption, and continue/stop loop. Updated the application sequence, human-task pipeline, pump-track page, docs index, and architecture summary to stay aligned.
---

created: 2026-08-28 00:12
---
Added the visual playback/resume slice: the guided-session page now renders the four-phase pump-track map, plays recorded events step by step, highlights the active phase/event, and persists playback_position through a resume endpoint. Chrome dogfood confirmed position 1 survives reload and returns to the same event. Updated BPMN-lite validation docs to distinguish the viewing cursor from action authorization.
---

created: 2026-08-28 00:14
---
Handoff verification found Rails CSRF blocked the playback cursor. Narrowed the playback action to local presentation state and verified in Chrome that playback position 1 survives reload and returns to the same event. No provider or application submission was performed.
---

created: 2026-08-28 17:19
---
Implemented the application-boundary vertical slice: the local extension records application-form arrival in Resolution, intercepts the guided sandbox form's final submit boundary, and records a pending irreversible submission_attempted event. The guided-session UI now exposes explicit Approve/Deny controls that record Mike's decision; approved execution remains a separate future seam. Focused suite: 15 examples, 0 failures; extension lint and focused RuboCop clean.
---

author: Codex
created: 2026-08-28 20:48
---
Captured the new application-research boundary. GuidedSession now has a durable Session Purpose: application_research or application_execution. Research sessions may enter and observe reversible provider steps, questions, and transitions without trying to submit; execution sessions may work toward applying under supervision. Purpose is context, not blanket permission: transmitting sensitive data, creating consequential persistent state, accepting terms, and final submission remain individually classified commitment boundaries. Intake defaults the human-facing choice to research while the database default preserves existing sessions as application_execution. Updated CONTEXT.md, ADR 005, and the BPMN-lite flow.
---

author: Codex
created: 2026-08-28 20:49
---
Chrome dogfood verified the new boundary end to end on localhost. The intake renders application research selected by default, preserves application execution as the alternate purpose, and created guided session #2 from the sandbox URL. The session page persisted “Application research” and states that the flow may be inspected and recorded without committing or submitting. No employer site was opened, no sensitive data was entered, and no application was submitted.
---

author: Codex
created: 2026-08-28 22:50
---
Implemented and verified the repeatable application-research observation slice. Guided-session pages now expose a tokenized “Open research flow” link. Extension v1.28.0 records a bounded, value-free application form structure (field key, label, control type, required state, identity/screening/demographic classification) and the local timeline renders it. Chrome opened the same tracked sandbox application twice from research session #2: both forms remained untouched, both observations recorded 6 fields and 2 screening questions, both field arrays produced one shared structure signature, and the session contained 0 submission_attempted events. Focused suite: 18 examples, 0 failures; extension lint, JS syntax, focused RuboCop, and diff checks passed.
---

author: Codex
created: 2026-08-28 22:52
---
Follow-on learning requirement captured as TASK-113. Guided-session research observations must feed a cross-application question graph: preserve each exact occurrence and its application/company/industry/provider/persona/outcome context, then group occurrences into reviewable archetypes and attach versioned answer strategies. TASK-112 remains responsible for trustworthy observation; TASK-113 owns cross-application clustering, answer-catalog analytics, and graph visualization.
---
<!-- COMMENTS:END -->
