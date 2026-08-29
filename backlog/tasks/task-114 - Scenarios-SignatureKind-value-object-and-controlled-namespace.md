---
id: TASK-114
title: 'Scenarios::SignatureKind value object and controlled namespace'
status: Done
assignee:
  - '@claude'
created_date: '2026-08-29 00:19'
updated_date: '2026-08-29 00:32'
labels:
  - architecture
  - signature-registry
  - reference-comparison
dependencies: []
documentation:
  - docs/adr/009-reference-comparison-drift-and-coverage.md
  - docs/architecture/signature-registry.md
  - app/models/scenario_signature.rb
  - app/services/scenarios/handshake_check.rb
modified_files:
  - app/services/scenarios/signature_kind.rb
  - spec/services/scenarios/signature_kind_spec.rb
  - docs/architecture/signature-registry.md
priority: medium
type: task
ordinal: 130000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
ADR 009 introduces structural signature kinds beyond the current bare ATS-identity kinds (job_post_id, ats_application_id, ...). Field structure, screening questions, step order, and commitment boundaries are all recorded as ScenarioSignature rows under a controlled namespace. Every consumer of a signature kind — ReferenceDiff, HandshakeCheck, coverage computation, presentation — must go through one parser/value-object boundary rather than splitting kind strings inline.

Provides for downstream tasks: a stable API for classifying and constructing namespaced kinds, and the frozen namespace whitelist they all validate against.

Namespaces: `field`, `screening_question`, `step`, `commitment_boundary`. Bare provider ids classify as `ats_identity`. An unrecognized namespace classifies as `unknown_namespace` — it must emit an observable diagnostic and be excluded from structural conclusions, never silently treated as a bare ATS identity. Development and test raise on an unknown namespace; production degrades with the diagnostic.

Screening-question kinds use a versioned normalized-text-hash identifier of the form `screening-question:v1:<sha256>` (archetype identity is deferred to TASK-113); the normalization version is part of the identifier so later migration is explainable.

No behaviour change to existing bare-kind handling — this is an additive boundary that existing kinds pass through unchanged.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Scenarios::SignatureKind parses a kind string into namespace + identifier and validates the namespace against a frozen whitelist (field, screening_question, step, commitment_boundary)
- [x] #2 A bare kind with no namespace prefix classifies as ats_identity and round-trips unchanged
- [x] #3 An unrecognized namespace classifies as unknown_namespace, emits an observable diagnostic, and is reported such that structural logic can exclude it; the parser raises in development and test environments
- [x] #4 Screening-question identifiers carry an explicit normalization version (screening-question:v1:<sha256>) and the value object exposes both the version and the hash
- [x] #5 Existing Scenarios::ReferenceDiff and Scenarios::HandshakeCheck behaviour is unchanged for the current bare kinds (regression coverage passes)
- [x] #6 Unit spec covers each namespace, the bare/ats_identity case, the unknown_namespace case in both raising and degrading modes, and the screening-question version accessor
- [x] #7 docs/architecture/signature-registry.md references the value object as the single kind-parsing boundary
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Approach

New value object `app/services/scenarios/signature_kind.rb` (namespace matches the existing `Scenarios::` service module; style follows `RoleFamily` — module-ish PORO, frozen constants, tiny methods for the Sandi-Metz rubocop limits).

Shape:
- `STRUCTURAL_NAMESPACES = %w[field screening_question step commitment_boundary].freeze`
- `SCREENING_QUESTION_VERSION = "v1"` + a documented v1 normalization (`strip`, collapse whitespace, downcase)
- `Parsed = Data.define(:raw, :namespace, :identifier)` with `#classification` (`:ats_identity` when no namespace, `:structural` when in whitelist, `:unknown_namespace` otherwise), predicate helpers, and `#screening_question_version` / `#screening_question_hash` (split the `<version>:<hash>` identifier).
- `.for(raw)` — the single parse entry point. Splits on the first `:` only (screening-question identifiers contain a `:`). On `:unknown_namespace`, logs `[SignatureKind] unknown namespace ...` (observable diagnostic) and raises `UnknownNamespaceError` when `Rails.env.local?` (dev + test); production returns the `:unknown_namespace` Parsed for the caller to exclude.
- Builders: `.build(namespace, identifier)` (validates against the whitelist) and `.screening_question(raw_text)` (normalizes, SHA256, prefixes `screening_question:v1:`).

No changes to `ScenarioSignature`, `ReferenceDiff`, or `HandshakeCheck` in this task — additive only. Consumers adopt it in TASK-116 / TASK-107.

Spec: `spec/services/scenarios/signature_kind_spec.rb` — each namespace, bare/ats_identity round-trip, unknown-namespace raising (test env) and the Parsed classification, screening-question version/hash accessors, builder validation.

Docs: `docs/architecture/signature-registry.md` names `Scenarios::SignatureKind` as the single kind-parsing boundary (paragraph already added when ADR 009 landed — tighten the wording).

Verify: `bundle exec rspec spec/services/scenarios/ spec/models/scenario_signature_spec.rb` + `rubocop` on the new files.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented as planned. Scenarios::SignatureKind is a class holding a Data.define Parsed value type plus class-method entry points (.for, .build, .screening_question). Sandi-Metz rubocop limits (5-line methods, AbcSize 10) drove two small extractions: validated_namespace, and a Parsed#unknown_namespace_warning helper so report_unknown stays under AbcSize.

v1 screening-question normalization is strip + collapse internal whitespace + downcase -- deliberately coarse (a reword still changes the hash; documented in ADR 009 and pointed at TASK-113).

Verification:
- bundle exec rspec spec/services/scenarios/ spec/models/scenario_signature_spec.rb spec/models/scenario_spec.rb -> 48 examples, 0 failures (includes the unchanged reference_diff / handshake_check / capture / promote_reference specs -> AC#5).
- bundle exec rspec spec/requests/docs_spec.rb -> 7 examples, 0 failures.
- bundle exec rubocop on both new files -> no offenses.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
## What changed

Adds `Scenarios::SignatureKind` (`app/services/scenarios/signature_kind.rb`) — the single boundary for reading or building a `ScenarioSignature#kind`, per ADR 009. Additive only: no existing model or service is modified, so every current bare kind is untouched.

### API
- `.for(raw)` → a `Parsed` value object (`Data.define(:raw, :namespace, :identifier)`) with `#classification` (`:ats_identity` for a bare kind, `:structural` for a whitelisted namespace, `:unknown_namespace` otherwise), predicates, and `#screening_question_version` / `#screening_question_hash`. Splits on the first `:` only, so `screening_question:v1:<sha>` keeps its structured identifier.
- `.build(namespace, identifier)` — constructs a namespaced kind; `ArgumentError` for a namespace outside `STRUCTURAL_NAMESPACES` (`field`, `screening_question`, `step`, `commitment_boundary`).
- `.screening_question(text)` — v1 normalization (trim, collapse whitespace, downcase) → `screening_question:v1:<sha256>`.

### Unknown-namespace handling
`:unknown_namespace` is logged (`Rails.logger.warn`) and raised (`UnknownNamespaceError`) when `Rails.env.local?` (dev + test); in production it logs and returns the `:unknown_namespace` `Parsed` so callers exclude it from structural conclusions. Vocabulary drift can't land silently, and can't hide as a bare ATS id.

## Tests
- `spec/services/scenarios/signature_kind_spec.rb` — new, 20 examples: each namespace, bare/ats_identity round-trip, unknown-namespace in both raising (test) and degrading (prod) modes, screening-question version/hash accessors + normalization equivalence, `.build` validation and round-trip.
- Regression: `spec/services/scenarios/` + scenario model specs → 48 examples, 0 failures (AC#5 — `ReferenceDiff` / `HandshakeCheck` unchanged).
- `spec/requests/docs_spec.rb` → 7/0. RuboCop clean on both new files.

## Follow-ups
No consumer is wired yet — that is TASK-116 (`ReferenceDiff` + coverage/drift) and TASK-107 (`HandshakeCheck` step-awareness), both of which depend on this. Uncommitted along with the ADR 009 / wayfinder-map changes from the same session.
<!-- SECTION:FINAL_SUMMARY:END -->
