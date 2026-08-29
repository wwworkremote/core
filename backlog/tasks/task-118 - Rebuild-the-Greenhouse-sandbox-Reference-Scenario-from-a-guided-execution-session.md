---
id: TASK-118
title: >-
  Rebuild the Greenhouse sandbox Reference Scenario from a guided execution
  session
status: To Do
assignee: []
created_date: '2026-08-29 00:20'
labels:
  - architecture
  - sandbox-provider
  - reference-comparison
dependencies:
  - TASK-115
documentation:
  - docs/adr/009-reference-comparison-drift-and-coverage.md
  - docs/architecture/sandbox-provider.md
  - docs/architecture/signature-registry.md
  - lib/tasks/scenarios.rake
  - app/services/scenarios/promote_reference.rb
priority: medium
type: task
ordinal: 134000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Per ADR 009. The current sandbox Greenhouse Reference Scenario (from the TASK-105 Phase A extension walkthrough) only holds bare ATS-identity signatures (job_post_id, ats_application_id) — it has no step:, field:, or commitment_boundary: markers, so there is nothing structural to compare a guided session against. The comparison loop (TASK-116/117) needs a reference that was captured the same way candidates are.

Depends on TASK-115 (Scenarios::Capture.from_guided_session) — that is the capture path this uses.

Scope:
- Run a complete application_execution guided session against the wwworkremote.localhost Greenhouse sandbox, all the way through the fake submit, so the session carries both pre-boundary steps (posting, form, fields, screening questions) and post-boundary steps (submit, confirmation, minted ats_application_id).
- Materialize it via Scenarios::Capture.from_guided_session and promote the resulting Scenario through the normal workflow (rake scenarios:reference_diff[TOKEN] PROMOTE=1 / Scenarios::PromoteReference).
- The Phase A extension walkthrough (TASK-105) stays as a lighter smoke check; it no longer defines the canonical structural reference. Note this in docs/architecture/sandbox-provider.md.
- The sandbox submission stays unmistakably synthetic and environment-isolated (Rails.env.local? gate, sandbox provider only). This task does not touch or relax commitment-boundary handling for real providers.
- Verification that the rebuilt reference is actually useful for comparison should be done together with TASK-116 (the comparison engine that consumes it).

Provider scope: Greenhouse sandbox only. Real-provider references remain TASK-109 / TASK-83.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A complete application_execution guided session is recorded against the Greenhouse sandbox through the fake submit and confirmation
- [ ] #2 That session is materialized via Scenarios::Capture.from_guided_session and promoted as the greenhouse ReferenceScenario through the normal preview-then-promote workflow
- [ ] #3 The promoted reference Scenario contains ordered step: markers on both sides of the first commitment_boundary: marker (pre-boundary posting/form/fields and post-boundary submit/confirmation)
- [ ] #4 The reference Scenario also contains the field: and screening_question: markers observed in the sandbox form
- [ ] #5 docs/architecture/sandbox-provider.md and signature-registry.md note that the canonical structural reference now comes from a guided execution session, with the Phase A walkthrough demoted to a smoke check
- [ ] #6 The sandbox remains environment-gated (Rails.env.local?) and no real provider or real submission is involved
<!-- AC:END -->
