---
id: TASK-117
title: 'ReferenceComparison, ComparisonFinding, FindingDisposition records'
status: To Do
assignee: []
created_date: '2026-08-29 00:20'
labels:
  - architecture
  - signature-registry
  - reference-comparison
dependencies:
  - TASK-116
documentation:
  - docs/adr/009-reference-comparison-drift-and-coverage.md
  - docs/architecture/signature-registry.md
  - CONTEXT.md
priority: high
type: feature
ordinal: 133000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Per ADR 009. The comparison engine (TASK-116) produces transient output; this task makes its results persistent, reviewable, and dispositionable so the loop supports replay, changed comparison rules, and learning from prior resolutions. Depends on TASK-116 so the concrete comparison output shape stabilizes the record validations.

Three layers (events establish what happened; findings establish what the comparison inferred; dispositions record what Mike decided):

- ReferenceComparison: one immutable row per comparison run, including failed or partial attempts (operational diagnosis matters). belongs_to :guided_session, belongs_to :scenario, belongs_to :reference_scenario (a real association, not only an id) with provider identifier and reference id also retained as run-time facts. comparison_rules_version stamped from Scenarios::ComparisonRules::VERSION. coverage jsonb is a versioned snapshot, not the canonical process model. ran_at.
- ComparisonFinding: immutable result of one run. category (drift | coverage_gap), dimension (signature_kind | field_structure | screening_question | step_order | commitment_boundary | provider_structural), locator (stable string identifying what diverged), detail jsonb.
- FindingDisposition: append-only human judgment. value in {provider_site_drift, reference_incomplete_or_stale, expected_persona_variation, expected_session_purpose_variation, unresolved}, rationale text, reviewer (stable actor reference where available plus a captured display label; a free-form string alone is fragile), resume_persona_id (nullable), created_at. Latest APPLICABLE disposition wins for presentation; earlier dispositions are never overwritten and remain first-class records.

Carry-forward: a new run's finding matching a prior (dimension, locator) — scoped by provider and reference lineage — surfaces the prior disposition as a suggested default ONLY. The new finding starts undispositioned and requires confirmation. Record the source disposition id whenever a suggestion is presented or accepted, so decision lineage stays explainable.

This task covers the models, associations, validations, immutability enforcement, and the carry-forward lookup — not the trigger or UI (TASK-119).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 ReferenceComparison, ComparisonFinding, FindingDisposition models + migrations exist matching the ADR 009 shape; ReferenceComparison associates reference_scenario as a real association and also retains provider + reference id as run-time facts
- [ ] #2 A ReferenceComparison row is created for every run attempt including failed and partial ones, and is immutable after creation (update attempts are rejected or have no effect)
- [ ] #3 ComparisonFinding rows are immutable after creation
- [ ] #4 FindingDisposition is append-only: a new disposition never mutates or deletes a prior one; the model exposes the latest applicable disposition without discarding history
- [ ] #5 Carry-forward lookup matches on (dimension, locator) scoped by provider and reference lineage, and returns a prior disposition as a suggestion with its source disposition id — it never auto-applies
- [ ] #6 A finding with a carried-forward suggestion is still undispositioned until a disposition is explicitly recorded; a spec proves a prior disposition is a suggestion with recorded lineage, never silently inherited
- [ ] #7 reviewer stores a stable actor reference where available plus a display label
- [ ] #8 Model specs cover immutability of the run and findings, append-only dispositions with history retained, and the scoped carry-forward match
- [ ] #9 CONTEXT.md and docs/architecture/signature-registry.md reflect the three-layer model (already drafted — verify accuracy against the built models)
<!-- AC:END -->
