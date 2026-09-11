---
id: TASK-112
title: 'Phase B: guided application session recorder with supervised intent'
status: In Progress
assignee:
  - '@mike'
created_date: '2026-08-27 22:17'
updated_date: '2026-08-30 23:38'
labels:
  - architecture
  - application-workflow
  - human-in-the-loop
dependencies: []
references:
  - TASK-105 (completed)
  - TASK-106 (completed)
  - TASK-113
  - docs/adr/009-reference-comparison-drift-and-coverage.md
  - TASK-119
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
- [x] #6 The recorded session is visible in the local app and can be compared with the provider Reference Scenario.
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

author: wayfinder
created: 2026-08-29 00:22
---
AC#6 ('recorded session ... can be compared with the provider Reference Scenario') is now specced in ADR 009 and delivered by TASK-119, which depends on TASK-114..TASK-118. See the wayfinder map 'Reference Comparison drift loop'. The remaining TASK-112 slices (AC#2-5: full phase/transition/field recording, intent classification, approval gating, deterministic replay) are unaffected and stay here.
---

author: claude
created: 2026-08-29 03:09
---
AC#6 delivered by TASK-119 (Done): GuidedSession#complete! runs one idempotent automatic ReferenceComparison; a review-page 'Compare to reference' button runs a manual one; the page renders the coverage phase/step map, drift findings, and a per-finding disposition control. Advisory only. AC#2-5 (full extension recording, intent classification, approval gating, deterministic replay) remain open here.
---

author: @claude
created: 2026-08-30 15:13
---
## Session 2026-08-30: AC#3 done, AC#4 reinforced, AC#5 planning half, AC#2 advanced

Merged to main `b8771de6` (branch `task-112-guided-recorder`). Full suite 1099 examples / 0 failures. Left **In Progress** — AC#2 wants a real-Chrome confirmation and AC#5's execution half is deliberately deferred (see below).

**AC#3 (annotate + classify) — done.** A "Reclassify" form on each timeline card (`PATCH guided_sessions/:id/events/:event_id` → new `GuidedSessions::EventsController#update`) lets the actor edit `intent` / `requirement` / `reversibility` / `approval_state`. The model still rejects an ungated `irreversible`. Also split `GuidedSessions::EventsController` + `GuidedSessions::DispositionsController` out of the oversized `GuidedSessionsController` (route helpers unchanged).

**AC#4 (irreversible ⇒ approval) — reinforced.** `GuidedSessionEvent#irreversible_transition_requires_approval` already enforces it model-side; added guardrail specs: `complete!` never auto-approves a pending `submission_attempted`; only `EventsController` mutates an event's `approval_state`.

**AC#5 (deterministic replay) — planning half built.** `GuidedSessions::ReplayPlan` classifies each recorded transition as auto-advanceable (deterministic, reversible, ungated) vs a pause gate (irreversible / approval-gated / commitment boundary), rendered read-only on the review page. **Execution — actually re-driving a browser — is [TASK-133](task-133), scoped as a Bounded Agency decision, not built.**

**AC#2 (real Chrome run records phases/transitions/field-actions/signatures into a reviewable timeline) — advanced, needs browser confirmation.**
- `content.js`: an SPA / hash step change during a guided session now records a page-arrival event, so multi-step ATS wizards produce a whole timeline (not only full-page reloads). `manifest.json` → **1.33.0**.
- The review page now summarises the fields filled during the session (label + source + time, never the value, joined by `session_token`) and surfaces captured provider signatures (`job_post_id`, `ats_application_id`) on each timeline card.
- Still open: a real dogfood pass through the loaded extension against a multi-step flow to confirm the wizard-step capture fires and the timeline reads whole.

**Unblocks [TASK-126](task-126)** — the guided-session `GuidedSessionEvent` stream is now rich enough (arrival + wizard steps + submission boundary) for per-event datalake asset capture.
---

author: claude
created: 2026-08-30 23:38
---
## Dogfood 2026-08-30 — machinery verified against the local /sandbox ATS (extension 1.36.0)

First real-browser guided session ever recorded (prior sessions were all `rake datalake:sandbox_walkthrough` sims). Claude drove; Mike's HITL ACs (#3 intent annotation, #4 approval, #5 replay-with-pause) still need a hands-on pass, but the surrounding machinery now has real evidence:

- **AC#1** — tracked_source_url + `?guided_session_token=&guided_session_purpose=` param flow works; content.js picks it up and records.
- **AC#2** — real recording works: `application_page_arrived` (with full form-structure extraction) and `submission_attempted` recorded, both visible in the `/guided_sessions/:id` RECORDED TIMELINE with classification chips. See TASK-126 comment #2 for detail.
- **AC#4** — Bounded Agency confirmed *in code*: content.js `submit` listener does `e.preventDefault(); e.stopImmediatePropagation()` and only records `submission_attempted`; the page did not navigate/submit on either the research or execution session. The timeline shows an Approve/Deny gate on that event.
- **AC#5** — the REPLAY PLAN panel renders ("pre-fill 1 step, pause for you at 1 gate"); the replay itself not exercised.
- **AC#6** — session visible in the local app; REFERENCE COMPARISON present with Complete session / Compare to reference.

Bugs found, filed separately: TASK-138 (research-mode screenshot permission gap, High), TASK-139 (execution debugger doesn't survive to the 2nd capture, Medium/confounded).

Still needs Mike: a hands-on pass doing real intent annotation + an Approve on the gate + a replay, ideally against a real ATS (the sandbox can't exercise HAR-with-bodies or multi-page transitions).
---
<!-- COMMENTS:END -->
