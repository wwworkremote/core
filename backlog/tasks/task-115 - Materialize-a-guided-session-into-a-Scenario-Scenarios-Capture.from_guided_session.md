---
id: TASK-115
title: >-
  Materialize a guided session into a Scenario
  (Scenarios::Capture.from_guided_session)
status: Done
assignee:
  - '@claude'
created_date: '2026-08-29 00:19'
updated_date: '2026-08-29 00:48'
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
modified_files:
  - app/services/scenarios/guided_capture.rb
  - app/services/scenarios/capture.rb
  - app/models/guided_session.rb
  - app/models/guided_session_event.rb
  - app/models/scenario_signature.rb
  - db/migrate/20260829000000_add_scenario_to_guided_sessions.rb
  - db/migrate/20260829000100_add_source_to_scenario_signatures.rb
  - db/schema.rb
  - spec/services/scenarios/guided_capture_spec.rb
  - spec/models/scenario_signature_spec.rb
  - docs/architecture/signature-registry.md
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
- [x] #1 Scenarios::Capture.from_guided_session builds a Scenario from a GuidedSession using only value-free GuidedSessionEvent evidence, with no dependency on retained raw DOM or HAR
- [x] #2 The materialized Scenario carries namespaced ScenarioSignature rows for fields, screening questions, steps reached, and commitment boundaries encountered, all constructed through Scenarios::SignatureKind, plus any available ATS identity signatures
- [x] #3 GuidedSession#scenario_id points to the materialized Scenario; re-running materialization for the same session does not create a second Scenario or duplicate signatures
- [x] #4 ScenarioSignature#source stores only value-free provenance; a write with a disallowed key or malformed source path is rejected
- [x] #5 A GuidedSessionEvent referenced by a ScenarioSignature#source cannot be destroyed while the reference exists
- [x] #6 Given identical GuidedSessionEvent evidence, materialization produces an identical set of signatures (deterministic) — proven by a spec that materializes the same fixture session twice and asserts equality
- [x] #7 No entered field values, email addresses, or answer text appear anywhere in the Scenario, its signatures, or the source breadcrumbs (spec asserts this against a session whose events contain populated evidence)
- [x] #8 Request/service spec coverage for the new path; docs/architecture/signature-registry.md 'what exists' table updated
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Research findings

- `GuidedSessionEvent.evidence` (jsonb) for `application_page_arrived` carries `{ page_title, provider, application_form, field_count, question_count, fields: [{ field_key, label, type, classification, required }] }`. `classification` ∈ `identity | screening_question | demographic` (screening questions are IN the `fields` array). `evidence["provider"]` is the canonical provider key (e.g. `"greenhouse"` for the sandbox) — `GuidedSession#provider` is only the host.
- `ScenarioSignature` is unique on `(scenario_id, kind, value)` with `find_or_create_by!` already used by `Scenarios::Capture` → idempotency is free.
- `Scenarios::Capture::PATTERNS` already extracts ATS ids from text (URL + JSON body).
- Schema is Rails 8.1; latest migration `20260828200000`.

## Approach

**Migrations** (2):
- `20260829000000_add_scenario_to_guided_sessions` — `add_reference :guided_sessions, :scenario, null: true, foreign_key: true` (nullable ownership pointer).
- `20260829000100_add_source_to_scenario_signatures` — `add_column :scenario_signatures, :source, :jsonb` (nullable; NULL = not from the guided path).

**Models**:
- `GuidedSession` — `belongs_to :scenario, optional: true`.
- `ScenarioSignature` — validate `source`: keys ⊆ `{guided_session_event_id, extracted_from}`, `extracted_from` matches a safe path regex; skip when nil.
- `GuidedSessionEvent` — `before_destroy` guard: `throw :abort` if any `ScenarioSignature.source->>'guided_session_event_id'` equals this id (also blocks the `GuidedSession dependent: :destroy` cascade — provenance is protected).

**`Scenarios::Capture.from_guided_session(guided_session)`** — thin delegator to a new `Scenarios::GuidedCapture` (keeps `Capture` under the 100-line class limit):
1. `scenario = guided_session.scenario || Scenario.create!(provider: canonical_provider, started_at: guided_session.started_at)`; set `guided_session.update!(scenario:)`.
2. Walk `guided_session.guided_session_events.order(:occurred_at, :id)`. Per event:
   - ATS ids: run `Capture::PATTERNS[provider]` over `page_url + evidence.to_json`; record bare kind, value = id, `source: {guided_session_event_id:, extracted_from: "page_url"|"evidence"}`.
   - `step:<phase>.<n>` (n = per-phase counter), value = event.kind, `first_observed_at` = occurred_at, `step` col = `"<phase>.<n>"`.
   - `reversibility == "irreversible"` → `commitment_boundary:<kind>`, value = approval_state.
   - `evidence["fields"]` → per field: `screening_question` class → kind `SignatureKind.screening_question(label)`, else kind `SignatureKind.build("field", field_key)`; value = `"<type>|<classification>|<required?>"`; `step` col = phase; `source.extracted_from = "evidence.fields[i]"`.
3. `canonical_provider` = first non-`"unknown"` `evidence["provider"]`, else host.
4. All writes via `find_or_create_by!(scenario:, kind:, value:)` → deterministic + idempotent; re-run reuses `guided_session.scenario`.
- No entered values (`fields[].label` is a question/label, not an answer; extension already strips values). Assert in spec.

**Spec**: `spec/services/scenarios/guided_capture_spec.rb` — materializes a fixture session (page_arrived + application_page_arrived + irreversible submission_attempted), asserts the namespaced signatures, the deterministic re-run (AC#6), the value-free guarantee against evidence containing populated-looking strings (AC#7), source rejection of a bad path/key, and the destroy guard.

**Docs**: `docs/architecture/signature-registry.md` "what exists" table row for the guided capture path → built.

Verify: `bundle exec rspec spec/services/scenarios/ spec/models/ spec/requests/guided_sessions_spec.rb spec/requests/api/` + rubocop + `bin/rails db:migrate` (and `db:rollback` sanity).
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Built as Scenarios::GuidedCapture (new file) with Scenarios::Capture.from_guided_session as a one-line delegator -- keeps Capture under the 100-line class limit and honours the AC's public API name.

Sandi-Metz rubocop limits (5-line methods, AbcSize 10, 4 params incl. kwargs) drove the shape: an Origin = Data.define(:event, :extracted_from, :step) value object carries the provenance trio as one unit through record_signature, and builds the source hash / observed_at itself. Several one-expression extractions (ats_text, first_match, screening_question?, field_shape).

Provider resolution: GuidedSession#provider is only the host (wwworkremote.localhost for the sandbox). Canonical provider = first non-"unknown" evidence["provider"] across events (the extension sends provider?.key, e.g. "greenhouse"), else the host. That is what keys Capture::PATTERNS and HandshakeCheck::SIGNATURE_EXPECTATIONS.

Signature value conventions: step: -> event.kind; commitment_boundary: -> approval_state; field:/screening_question: -> "<type>|<classification>|<required|optional>" (a compact structural fingerprint so a field/question changing shape appends a new row); ATS ids -> the matched id. step column = "<phase>.<n>" for step markers, the phase for fields.

Provenance protection: GuidedSessionEvent#before_destroy throw :abort when any ScenarioSignature.source->>'guided_session_event_id' == id. This also blocks the GuidedSession dependent: :destroy cascade for a materialized session -- verified by spec (session.destroy leaves the events in place).

Migrations use safety_assured (guided_sessions is days old, a handful of dev rows). Rollback + re-migrate verified clean.

Verification:
- spec/services/scenarios/guided_capture_spec.rb (7) + scenario_signature_spec #source (3) + full spec/services/scenarios/ + scenario models + guided_sessions + api/guided_session_events + api/scenarios -> 77 examples, 0 failures.
- spec/requests/docs_spec.rb -> 7, 0.
- RuboCop clean on all 18 touched files. db:rollback STEP=2 / db:migrate round-trips cleanly.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
## What changed

Adds `Scenarios::GuidedCapture` (and `Scenarios::Capture.from_guided_session` as its public delegator) — the value-free path that materializes a `GuidedSession` into an ordinary `Scenario` so Reference Comparison reuses `ReferenceDiff` / `HandshakeCheck` / promotion (ADR 009).

### Behaviour
Walks the session's `GuidedSessionEvent`s in `occurred_at` order and emits `ScenarioSignature` rows, all kinds built through `Scenarios::SignatureKind` (TASK-114):
- `step:<phase>.<n>` — one per event (value = event kind)
- `commitment_boundary:<kind>` — one per irreversible event (value = approval state)
- `field:<field_key>` / `screening_question:v1:<sha>` — one per observed form field/question (value = `<type>|<classification>|<required|optional>` structural fingerprint)
- bare ATS ids — matched from `page_url` + `evidence.to_json` via the existing `Capture::PATTERNS`

Canonical provider is resolved from `evidence["provider"]` (the host alone isn't enough for the sandbox). Deterministic and idempotent: re-running reuses `GuidedSession#scenario_id` and the `(scenario_id, kind, value)` unique index no-ops repeats.

### Schema
- `guided_sessions.scenario_id` (nullable FK) — the ownership pointer.
- `scenario_signatures.source` (nullable jsonb) — value-free provenance breadcrumb `{guided_session_event_id, extracted_from}`, validated for permitted keys and a plain-path `extracted_from`; NULL on the HAR/DOM path.
- `GuidedSessionEvent#before_destroy` blocks pruning any event a signature points at — including via the `GuidedSession` dependent-destroy cascade.

## Tests
- `spec/services/scenarios/guided_capture_spec.rb` (7) — signature emission across all namespaces, canonical provider, value-free provenance + phase step, deterministic re-run, no-entered-value guarantee against poisoned evidence, both provenance-protection paths.
- `spec/models/scenario_signature_spec.rb` `#source` (3) — breadcrumb shape accepted, bad key and non-path `extracted_from` rejected.
- Regression: full `spec/services/scenarios/` + scenario models + `guided_sessions` + `api/guided_session_events` + `api/scenarios` → 77 examples, 0 failures. `docs_spec` 7/0. RuboCop clean (18 files). Migrations round-trip.

## Follow-ups
`TASK-116` (extend `ReferenceDiff` to coverage-vs-drift over these markers) and `TASK-118` (rebuild the sandbox Greenhouse reference through this path) are now unblocked. No consumer reads the new markers yet.
<!-- SECTION:FINAL_SUMMARY:END -->
