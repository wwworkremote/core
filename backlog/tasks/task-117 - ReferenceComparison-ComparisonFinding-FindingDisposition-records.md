---
id: TASK-117
title: 'ReferenceComparison, ComparisonFinding, FindingDisposition records'
status: Done
assignee:
  - '@claude'
created_date: '2026-08-29 00:20'
updated_date: '2026-08-29 02:09'
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
modified_files:
  - db/migrate/20260829010000_create_reference_comparisons.rb
  - db/migrate/20260829010100_create_comparison_findings.rb
  - db/migrate/20260829010200_create_finding_dispositions.rb
  - db/schema.rb
  - app/models/reference_comparison.rb
  - app/models/comparison_finding.rb
  - app/models/finding_disposition.rb
  - app/services/scenarios/record_comparison.rb
  - spec/factories/reference_comparisons.rb
  - spec/models/reference_comparison_spec.rb
  - spec/models/comparison_finding_spec.rb
  - spec/models/finding_disposition_spec.rb
  - spec/services/scenarios/record_comparison_spec.rb
  - docs/architecture/signature-registry.md
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
- [x] #1 ReferenceComparison, ComparisonFinding, FindingDisposition models + migrations exist matching the ADR 009 shape; ReferenceComparison associates reference_scenario as a real association and also retains provider + reference id as run-time facts
- [x] #2 A ReferenceComparison row is created for every run attempt including failed and partial ones, and is immutable after creation (update attempts are rejected or have no effect)
- [x] #3 ComparisonFinding rows are immutable after creation
- [x] #4 FindingDisposition is append-only: a new disposition never mutates or deletes a prior one; the model exposes the latest applicable disposition without discarding history
- [x] #5 Carry-forward lookup matches on (dimension, locator) scoped by provider and reference lineage, and returns a prior disposition as a suggestion with its source disposition id — it never auto-applies
- [x] #6 A finding with a carried-forward suggestion is still undispositioned until a disposition is explicitly recorded; a spec proves a prior disposition is a suggestion with recorded lineage, never silently inherited
- [x] #7 reviewer stores a stable actor reference where available plus a display label
- [x] #8 Model specs cover immutability of the run and findings, append-only dispositions with history retained, and the scoped carry-forward match
- [x] #9 CONTEXT.md and docs/architecture/signature-registry.md reflect the three-layer model (already drafted — verify accuracy against the built models)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Approach

Three tables + models + the persistence service that maps a `Scenarios::DriftAnalysis` result onto rows. (The recorder is persistence, not trigger/UI — TASK-119 only wires *when* it runs and renders it.)

**Migrations (3, `safety_assured` — new tables):**
1. `create_reference_comparisons` — `guided_session_id` FK, `scenario_id` FK, `reference_scenario_id` FK (nullable), `provider` not null, `comparison_rules_version` not null, `coverage` jsonb default {}, `outcome` not null (`ok`|`no_reference`|`failed`), `error` nullable, `trigger` not null (`automatic`|`manual`), `ran_at` not null. Index `guided_session_id`, `(provider, reference_scenario_id)`.
2. `create_comparison_findings` — `reference_comparison_id` FK, `category` not null (`drift`|`coverage_gap`), `dimension` not null, `locator` not null, `detail` jsonb default {}, `suggested_disposition_id` bigint nullable (soft pointer, no FK). Index `reference_comparison_id`, `(dimension, locator)`.
3. `create_finding_dispositions` — `comparison_finding_id` FK, `value` not null, `rationale` text, `reviewer` not null, `reviewer_label` nullable, `resume_persona_id` nullable, `source_disposition_id` bigint nullable (soft pointer). Index `(comparison_finding_id, created_at)`.

**Models:**
- `ReferenceComparison` — associations, `inclusion` validations (guided_session pattern), `before_validation` sets `ran_at`, **`readonly? => persisted?`** (immutable after create — covers every attempt incl. failed/partial). `has_many :comparison_findings`.
- `ComparisonFinding` — `CATEGORIES`, `DIMENSIONS` = the `Scenarios::SignatureKind` dimensions (`ats_identity field screening_question step commitment_boundary unknown_namespace` — the ADR's illustrative list is superseded by the TASK-114 vocabulary), `readonly? => persisted?`. `#current_disposition` = latest `finding_disposition` by `created_at, id`; `#dispositioned?`. `belongs_to :suggested_disposition, class_name: "FindingDisposition", optional: true`.
- `FindingDisposition` — `VALUES` (the 5), `belongs_to :source_disposition` self-ref optional, `readonly? => persisted?` (append-only). `.latest_for(dimension:, locator:, provider:, reference_scenario_id:)` — the carry-forward lookup, scoped by provider + reference lineage, newest first.

**`Scenarios::RecordComparison.call(guided_session, trigger:)`:**
1. `scenario = Scenarios::Capture.from_guided_session(guided_session)` (idempotent).
2. `reference = ReferenceScenario.find_by(provider: scenario.provider)&.scenario`; nil → persist `outcome: "no_reference"`, return.
3. `analysis = Scenarios::DriftAnalysis.call(...)` rescued → `outcome: "failed", error:`.
4. persist `ReferenceComparison(outcome: "ok", coverage: analysis[:coverage], comparison_rules_version: analysis[:rules_version], provider:, trigger:, ...)`.
5. drift: one `ComparisonFinding(category: "drift", dimension: SignatureKind.for(kind).dimension, locator: kind, detail: {change:})` per gained/lost/changed kind. coverage: one `(category: "coverage_gap", dimension: "step", locator: checkpoint_kind)` per applicable `not_reached` checkpoint.
6. each finding: `suggested_disposition = FindingDisposition.latest_for(...)` — set as a *suggestion only*; finding is undispositioned until a real `FindingDisposition` row is written.

## Specs
- `reference_comparison_spec` — immutable after create (update raises `ReadonlyRecord`); associations; `ran_at` default.
- `comparison_finding_spec` — immutable; `current_disposition` = latest by created_at; `dispositioned?`.
- `finding_disposition_spec` — append-only (a second row doesn't touch the first; both retained); `.latest_for` scoped by provider + reference; value inclusion.
- `record_comparison_spec` — builds a comparison + drift + coverage_gap findings from a fixture session+reference; `no_reference` path; carry-forward: a prior disposition on a matching `(dimension, locator)` for the same provider/reference is attached as `suggested_disposition` and the new finding is still `dispositioned? == false`; a different provider does NOT carry forward.

## Verify
`bundle exec rspec spec/models spec/services/scenarios` + rubocop + `bin/rails db:migrate` round-trip + `docs_spec`. Update `signature-registry.md` "what exists" row + CONTEXT.md if the built shape differs from the drafted glossary.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
3 models + 3 migrations + Scenarios::RecordComparison (the DriftAnalysis-result -> rows mapper; TASK-119 owns *when* it runs and rendering).

- Immutability: `def readonly? = persisted?` on ReferenceComparison + ComparisonFinding + FindingDisposition. A create is allowed; any later `update!` raises `ActiveRecord::ReadOnlyRecord` (note: Rails 8.1 class is ReadOnlyRecord, capital O). FindingDisposition is append-only by the same mechanism -- new rows fine, updates blocked.
- ComparisonFinding::DIMENSIONS uses the Scenarios::SignatureKind vocabulary (ats_identity / field / screening_question / step / commitment_boundary / unknown_namespace). ADR 009's illustrative dimension list (signature_kind / field_structure / step_order / provider_structural) is superseded by TASK-114's namespaces -- one vocabulary, not two.
- reviewer (required) + reviewer_label (optional display) columns; resume_persona_id nullable; source_disposition_id + suggested_disposition_id are plain bigints (soft pointers to historical rows, no FK -- they reference data that must not constrain deletes).
- Carry-forward: FindingDisposition.latest_for(dimension:, locator:, provider:, reference_scenario_id:) joins through comparison_finding -> reference_comparison, newest first. RecordComparison sets it as ComparisonFinding#suggested_disposition; the new finding's #dispositioned? stays false until a real FindingDisposition is written.
- RecordComparison outcomes: ok (with findings), no_reference (provider has no ReferenceScenario -- advisory, not an error), failed (DriftAnalysis raised -- error string captured). `trigger` column (automatic|manual) so TASK-119 can enforce one-automatic-run-per-completed-transition.

Verification:
- spec/models/{reference_comparison,comparison_finding,finding_disposition}_spec.rb + spec/services/scenarios/record_comparison_spec.rb -> 18 examples, 0 failures.
- Broad regression: spec/models + spec/services/scenarios + guided_sessions + api/guided_session_events + api/scenarios + docs_spec -> 272 examples, 0 failures.
- RuboCop clean (9 files). Migrations rollback STEP=3 / migrate round-trip clean.
- CONTEXT.md glossary (Finding / Disposition / the 5 values / append-only-latest-wins) verified accurate against the built models -- no change needed. signature-registry.md "what exists" row updated.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
## What changed

The persistent three-layer model for ADR 009 — events (existing `GuidedSessionEvent`) establish what happened, **findings** establish what the comparison inferred, **dispositions** record what Mike decided.

### Models + migrations
- **`ReferenceComparison`** — one immutable row per run (`outcome` ∈ `ok` / `no_reference` / `failed`, so every attempt is recorded), `trigger` ∈ `automatic` / `manual`, `comparison_rules_version` stamped, `coverage` jsonb snapshot, `ran_at`. Real `reference_scenario` association plus `provider` retained as a run-time fact.
- **`ComparisonFinding`** — immutable; `category` ∈ `drift` / `coverage_gap`, `dimension` (the `Scenarios::SignatureKind` vocabulary), `locator` (the stable divergence id — a signature kind or checkpoint kind), `detail` jsonb, `suggested_disposition` (carry-forward pointer).
- **`FindingDisposition`** — append-only; `value` (the five), `reviewer` + `reviewer_label`, `resume_persona_id`, `source_disposition_id` (lineage when a suggestion is accepted). `ComparisonFinding#current_disposition` = latest by `created_at, id`; history stays queryable.

Immutability enforced by `def readonly? = persisted?` on all three — a later `update!` raises `ActiveRecord::ReadOnlyRecord`.

### `Scenarios::RecordComparison.call(guided_session, trigger:)`
Materializes the session (`Scenarios::Capture.from_guided_session`), resolves the provider `ReferenceScenario`, runs `Scenarios::DriftAnalysis`, and writes the run + one `ComparisonFinding` per drift kind / unreached applicable checkpoint. Each finding gets `FindingDisposition.latest_for(dimension:, locator:, provider:, reference_scenario_id:)` as a **suggestion only** — `#dispositioned?` stays false until a real disposition is written. Carry-forward never crosses provider or reference lineage.

## Tests
- `reference_comparison_spec`, `comparison_finding_spec`, `finding_disposition_spec`, `record_comparison_spec` — 18 examples: immutability of runs + findings, append-only dispositions with history retained, `.latest_for` scoping, `no_reference` path, suggestion-not-inheritance.
- Broad regression: `spec/models` + `spec/services/scenarios` + guided-session + API + docs specs → **272 examples, 0 failures**. RuboCop clean. Migrations round-trip.

## Follow-ups
**TASK-119** (trigger on `completed` + "Compare to Reference" action + review-page findings/disposition UI, closes TASK-112 AC#6) now has everything it needs. **TASK-107** (step-aware `HandshakeCheck`) and **TASK-118** (rebuild sandbox reference) are independent and still open.
<!-- SECTION:FINAL_SUMMARY:END -->
