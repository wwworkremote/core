---
id: TASK-115
title: >-
  Materialize a guided session into a Scenario
  (Scenarios::Capture.from_guided_session)
status: To Do
assignee: []
created_date: '2026-08-29 00:19'
labels:
  - architecture
  - signature-registry
  - reference-comparison
dependencies:
  - TASK-114
documentation:
  - docs/adr/009-reference-comparison-drift-and-coverage.md
  - docs/architecture/signature-registry.md
  - docs/architecture/guided-session-flow.md
  - app/services/scenarios/capture.rb
  - app/models/guided_session.rb
  - app/models/guided_session_event.rb
  - app/models/scenario.rb
  - app/models/scenario_signature.rb
priority: high
type: feature
ordinal: 131000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Per ADR 009, comparing a guided session against a Reference Scenario starts by materializing the session into an ordinary Scenario so the existing ReferenceDiff / PromoteReference / rake tooling applies. This task builds only the materialization path; comparison itself is TASK-116.

Depends on TASK-114 for Scenarios::SignatureKind — the namespaced kinds this path writes (field:, screening_question:, step:, commitment_boundary:) must be constructed and validated through that value object.

Scope:
- Add Scenarios::Capture.from_guided_session (a new entry path alongside the existing HAR/DOM text path) that reads the value-free GuidedSessionEvent evidence directly. Raw DOM/HAR retention must NOT become a prerequisite.
- Emit ScenarioSignature rows for: ATS identity signatures already available from event page_url / evidence; each observed form field (field:<key>); each screening question (screening-question:v1:<sha256> via SignatureKind); each ordered step reached (step:<phase>.<ordinal>); each commitment boundary encountered (commitment_boundary:<name>). Ordering comes from the source event occurred_at written into first_observed_at / step.
- Add GuidedSession#scenario_id (nullable) as the ownership pointer to the materialized result.
- Add ScenarioSignature#source (nullable jsonb): value-free provenance only, e.g. {"guided_session_event_id": N, "extracted_from": "evidence.fields[2].key"}. Validate permitted keys and source-path syntax at write time. A GuidedSessionEvent referenced by any signature source must be protected from deletion/pruning while the reference exists.
- Materialization is deterministic: the same immutable event evidence produces the same Scenario + signatures. Re-running is idempotent (the existing scenario_signatures unique index plus passing the existing Scenario back in).
- No sensitive values (entered text, email, answers) are ever copied into the Scenario, signatures, or source breadcrumbs.

The event evidence stays the immutable full-fidelity provenance; the Scenario is the normalized comparison artifact.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Scenarios::Capture.from_guided_session builds a Scenario from a GuidedSession using only value-free GuidedSessionEvent evidence, with no dependency on retained raw DOM or HAR
- [ ] #2 The materialized Scenario carries namespaced ScenarioSignature rows for fields, screening questions, steps reached, and commitment boundaries encountered, all constructed through Scenarios::SignatureKind, plus any available ATS identity signatures
- [ ] #3 GuidedSession#scenario_id points to the materialized Scenario; re-running materialization for the same session does not create a second Scenario or duplicate signatures
- [ ] #4 ScenarioSignature#source stores only value-free provenance; a write with a disallowed key or malformed source path is rejected
- [ ] #5 A GuidedSessionEvent referenced by a ScenarioSignature#source cannot be destroyed while the reference exists
- [ ] #6 Given identical GuidedSessionEvent evidence, materialization produces an identical set of signatures (deterministic) — proven by a spec that materializes the same fixture session twice and asserts equality
- [ ] #7 No entered field values, email addresses, or answer text appear anywhere in the Scenario, its signatures, or the source breadcrumbs (spec asserts this against a session whose events contain populated evidence)
- [ ] #8 Request/service spec coverage for the new path; docs/architecture/signature-registry.md 'what exists' table updated
<!-- AC:END -->
