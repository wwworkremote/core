---
id: TASK-116
title: Extend ReferenceDiff to coverage-vs-drift over namespaced markers
status: To Do
assignee: []
created_date: '2026-08-29 00:20'
updated_date: '2026-08-29 00:22'
labels:
  - architecture
  - signature-registry
  - reference-comparison
dependencies:
  - TASK-114
  - TASK-115
documentation:
  - docs/adr/009-reference-comparison-drift-and-coverage.md
  - docs/architecture/signature-registry.md
  - app/services/scenarios/reference_diff.rb
  - app/services/scenarios/handshake_check.rb
priority: high
type: feature
ordinal: 132000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Per ADR 009. Once a guided session materializes into a Scenario with namespaced markers (TASK-115), the comparison logic against a Reference Scenario has to become overlap-aware and commitment-boundary-aware. This is the comparison engine; the persistent records that wrap it are TASK-117, the trigger/UI is TASK-119, and the parallel HandshakeCheck update is TASK-107.

Scope:
- Extend Scenarios::ReferenceDiff to diff namespaced markers (field:, screening_question:, step:, commitment_boundary:) using its existing gained/lost/reordered logic, via Scenarios::SignatureKind (TASK-114). Keep bare ats_identity diffing unchanged.
- Introduce the coverage-vs-drift split, as a service the diff exposes or a sibling service:
  - Reached Scope = the portion of the reference the session reached, bounded by GuidedSession#purpose and where it stopped.
  - Drift = differences within the observed overlap only.
  - Coverage = applicable checkpoints reached / applicable reference checkpoints, where a checkpoint is an ordered distinct reference step: marker. For application_research, the FIRST commitment_boundary: checkpoint stays applicable and visible (the intentional stop); checkpoints beyond it are not applicable. Zero applicable checkpoints => coverage is 'unavailable', never 0% or 100%.
  - The coverage result carries a per-checkpoint phase/step map (reached / not reached / not applicable), not only a ratio.
- Add Scenarios::ComparisonRules::VERSION as a frozen constant for TASK-117 to stamp onto a run. Document that it is bumped only when identical evidence could produce materially different findings or coverage — not for formatting, presentation, or performance changes.

HandshakeCheck step-awareness is TASK-107, a sibling slice consuming the same step/checkpoint model. Provider-neutral mechanism; the only worked example is the Greenhouse sandbox.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Scenarios::ReferenceDiff diffs namespaced markers (field/screening_question/step/commitment_boundary) via Scenarios::SignatureKind, with bare ats_identity behaviour unchanged (existing specs pass)
- [ ] #2 Drift is computed only within Reached Scope (the observed overlap), not against reference markers beyond where the session stopped
- [ ] #3 Coverage is applicable-checkpoints-reached over applicable-reference-checkpoints; for an application_research session the first commitment boundary is applicable and checkpoints past it are not applicable
- [ ] #4 A research session that stops at the first commitment boundary produces coverage information (incomplete coverage, boundary shown as the intentional stop) and produces zero false drift findings — proven by a spec
- [ ] #5 Coverage with zero applicable checkpoints reports 'unavailable', not a percentage
- [ ] #6 The coverage result includes a per-checkpoint phase/step map (reached / not reached / not applicable), not only a ratio
- [ ] #7 Scenarios::ComparisonRules::VERSION exists as a frozen constant with a documented bump policy
- [ ] #8 Spec coverage for the diff extension and the coverage/drift split
<!-- AC:END -->
