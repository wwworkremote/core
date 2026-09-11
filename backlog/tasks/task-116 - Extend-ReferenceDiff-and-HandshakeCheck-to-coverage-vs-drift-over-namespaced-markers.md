---
id: TASK-116
title: Extend ReferenceDiff to coverage-vs-drift over namespaced markers
status: Done
assignee:
  - '@claude'
created_date: '2026-08-29 00:20'
updated_date: '2026-08-29 01:10'
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
modified_files:
  - app/services/scenarios/comparison_rules.rb
  - app/services/scenarios/reference_diff.rb
  - app/services/scenarios/coverage.rb
  - app/services/scenarios/drift_analysis.rb
  - app/services/scenarios/signature_kind.rb
  - spec/services/scenarios/comparison_rules_spec.rb
  - spec/services/scenarios/reference_diff_spec.rb
  - spec/services/scenarios/coverage_spec.rb
  - spec/services/scenarios/drift_analysis_spec.rb
  - spec/support/scenario_signature_builder.rb
  - docs/architecture/signature-registry.md
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
- [x] #1 Scenarios::ReferenceDiff diffs namespaced markers (field/screening_question/step/commitment_boundary) via Scenarios::SignatureKind, with bare ats_identity behaviour unchanged (existing specs pass)
- [x] #2 Drift is computed only within Reached Scope (the observed overlap), not against reference markers beyond where the session stopped
- [x] #3 Coverage is applicable-checkpoints-reached over applicable-reference-checkpoints; for an application_research session the first commitment boundary is applicable and checkpoints past it are not applicable
- [x] #4 A research session that stops at the first commitment boundary produces coverage information (incomplete coverage, boundary shown as the intentional stop) and produces zero false drift findings — proven by a spec
- [x] #5 Coverage with zero applicable checkpoints reports 'unavailable', not a percentage
- [x] #6 The coverage result includes a per-checkpoint phase/step map (reached / not reached / not applicable), not only a ratio
- [x] #7 Scenarios::ComparisonRules::VERSION exists as a frozen constant with a documented bump policy
- [x] #8 Spec coverage for the diff extension and the coverage/drift split
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Research

- `Scenarios::ReferenceDiff.call(candidate, reference:)` returns `{provider, candidate, reference, gained, lost, reordered}` where `candidate`/`reference` are ordered `pluck(:kind)`. The existing spec asserts with `include(...)` → adding keys is backward-compatible; the `scenarios:reference_diff` rake task just `JSON.pretty_generate`s it.
- Namespaced kinds already flow through the kind-only set diff. What's missing: (a) bucketing by dimension, (b) *value* changes within a same-kind (a `field:`/`screening_question:` whose `<type>|<classification>|<required>` fingerprint changed — invisible today), (c) the coverage-vs-drift / Reached-Scope split, (d) purpose-awareness (purpose lives on `GuidedSession`, not `Scenario`).

## Approach — 4 small units

1. **`Scenarios::ComparisonRules`** — `VERSION = "1"` frozen constant + a doc comment stating the bump policy (only when identical evidence could yield materially different findings/coverage; not formatting/presentation/perf).

2. **`Scenarios::ReferenceDiff`** — keep all existing keys; add:
   - `changed`: kinds present in both candidate and reference whose latest `value` differs (structural-fingerprint drift).
   - `dimensions`: `{ ats_identity:, field:, screening_question:, step:, commitment_boundary:, unknown_namespace: }`, each `{ gained:, lost:, changed: }`, bucketed via `Scenarios::SignatureKind.for(kind).classification` / namespace.
   - Existing `gained`/`lost`/`reordered` stay as the all-kinds rollup.

3. **`Scenarios::Coverage`** — `call(candidate, reference:, purpose:)`:
   - checkpoints = reference `step:` markers in `first_observed_at, id` order.
   - research applicability: a checkpoint whose sequence position is after the first reference `commitment_boundary:` marker is `not_applicable` when `purpose == "application_research"`; the boundary itself stays visible.
   - per checkpoint `{ kind, step, status: reached | not_reached | not_applicable }` (`reached` = kind ∈ candidate kinds).
   - `ratio` = applicable-reached / applicable; `status: "unavailable"` + `ratio: nil` when applicable count is 0.

4. **`Scenarios::DriftAnalysis`** — `call(candidate, reference:, purpose:)` → `{ rules_version:, coverage:, drift: { gained:, lost:, changed: } }`.
   - Reached Scope = reference signatures up to and including the position of the last reference marker whose kind the candidate also has.
   - `drift.lost` = reference-only kinds **within** Reached Scope (a marker that should have appeared by where the run got, and didn't). Reference-only kinds **beyond** Reached Scope are coverage gaps, not drift.
   - `drift.gained` = candidate-only kinds (always drift). `drift.changed` = value changes (always drift).

## Scope guards
- Bare `ats_identity` diff output unchanged (existing `reference_diff_spec` passes).
- Provider-neutral; specs use greenhouse-shaped fixtures.
- Findings/dispositions persistence is TASK-117; HandshakeCheck is TASK-107. This task returns plain hashes only.

## Specs
`reference_diff_spec` (extend: `changed`, `dimensions`), new `coverage_spec` (research truncation → not_applicable + zero false drift, execution → full, zero-applicable → unavailable, per-checkpoint map), new `drift_analysis_spec` (lost within scope = drift, lost beyond scope = coverage gap; gained/changed always drift; `rules_version` stamped). `comparison_rules_spec` (VERSION present + frozen).

## Verify
`bundle exec rspec spec/services/scenarios/` + rubocop + `docs_spec`. Update `docs/architecture/signature-registry.md` "what exists" rows.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Landed as 4 units (all plain-hash, no persistence, no authorization):
- Scenarios::ComparisonRules::VERSION = "1" (frozen module const) + bump-policy comment.
- Scenarios::ReferenceDiff: keeps every existing key (rake task + old spec assert with include(...)); adds `changed` (kinds in both whose latest value differs) and `dimensions` (per-namespace {gained,lost,changed} bucketed via Scenarios::SignatureKind#dimension -- a new one-line accessor on Parsed returning the namespace / "ats_identity" / "unknown_namespace").
- Scenarios::Coverage.call(candidate, reference:, purpose:): checkpoints = reference step: markers in order; for application_research any checkpoint sequenced after the first commitment_boundary: marker is not_applicable; per-checkpoint {kind, step, status}; ratio = reached/applicable, status "unavailable" + ratio nil when zero applicable.
- Scenarios::DriftAnalysis.call(...): {rules_version, coverage, drift:{gained,lost,changed}}. Reached Scope = reference kinds up to the rindex of the last reference kind the candidate also has; drift.lost = reference-only kinds within that scope (past it is a coverage gap). gained + changed are always drift.

Sandi-Metz limits drove several one-expression extractions and the removal of an each_with_object in favour of to_h.

Verification:
- spec/services/scenarios/{comparison_rules,reference_diff,coverage,drift_analysis}_spec.rb + extended reference_diff_spec -> covered; full spec/services/scenarios/ + scenario model specs -> 69 examples, 0 failures.
- spec/requests/docs_spec.rb -> 7, 0. RuboCop clean (19 files). Existing reference_diff_spec unchanged assertions still pass (bare ats_identity behaviour intact).
- New spec/support/scenario_signature_builder.rb (auto-required) expresses an ordered [kind,value] marker sequence as a Scenario.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
## What changed

The advisory comparison engine for ADR 009 — plain-hash output, no persistence, never authorizes or advances anything.

- **`Scenarios::ComparisonRules::VERSION`** — frozen `"1"`, stamped onto every run; bump-policy documented (only when identical evidence could yield materially different findings/coverage).
- **`Scenarios::ReferenceDiff`** — keeps every existing key (rake task + old spec unaffected); adds `changed` (same kind in both, different latest value — the structural-fingerprint drift that was invisible) and `dimensions` (per-namespace `{gained, lost, changed}`, bucketed via a new `Scenarios::SignatureKind::Parsed#dimension`).
- **`Scenarios::Coverage.call(candidate, reference:, purpose:)`** — checkpoints = reference `step:` markers in order; for `application_research`, checkpoints sequenced after the first `commitment_boundary:` are `not_applicable` (boundary stays visible); per-checkpoint `{kind, step, status}`; `ratio` derived, `status: "unavailable"` + `ratio: nil` when zero applicable.
- **`Scenarios::DriftAnalysis.call(...)`** — `{rules_version, coverage, drift: {gained, lost, changed}}`. Reached Scope bounds `drift.lost` to reference-only markers the run should have produced by where it got; anything past the last reached reference position is a coverage gap, not drift. `gained` and `changed` are always drift.

## Tests
- `comparison_rules_spec`, `coverage_spec` (5), `drift_analysis_spec` (5), extended `reference_diff_spec` — research truncation → `not_applicable` + **zero false drift**, execution → full ratio, zero-applicable → `unavailable`, per-checkpoint map, lost-in-scope vs coverage-gap, gained/changed always drift.
- Full `spec/services/scenarios/` + scenario models → 69 examples, 0 failures. `docs_spec` 7/0. RuboCop clean (19 files). Existing `reference_diff_spec` bare-`ats_identity` assertions unchanged.
- New auto-required `spec/support/scenario_signature_builder.rb`.

## Follow-ups
`TASK-117` (persist `ReferenceComparison` / `ComparisonFinding` / `FindingDisposition` around this output) and `TASK-107` (step-aware `HandshakeCheck` over the same `step:` / `commitment_boundary:` vocabulary) are now unblocked. `TASK-118` (rebuild the sandbox reference) can proceed in parallel.
<!-- SECTION:FINAL_SUMMARY:END -->
