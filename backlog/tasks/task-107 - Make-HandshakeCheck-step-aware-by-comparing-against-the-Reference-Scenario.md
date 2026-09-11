---
id: TASK-107
title: Step-aware HandshakeCheck against ADR-009 markers
status: Done
assignee:
  - '@claude'
created_date: '2026-08-27 17:25'
updated_date: '2026-08-29 02:12'
labels:
  - architecture
  - signature-registry
  - reference-comparison
dependencies:
  - TASK-114
  - TASK-116
references:
  - docs/adr/009-reference-comparison-drift-and-coverage.md
  - TASK-116
documentation:
  - docs/architecture/signature-registry.md
  - app/services/scenarios/handshake_check.rb
modified_files:
  - app/services/scenarios/handshake_check.rb
  - spec/services/scenarios/handshake_check_spec.rb
  - docs/architecture/signature-registry.md
priority: medium
type: enhancement
ordinal: 132500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Rewritten to align with ADR 009 (docs/adr/009-reference-comparison-drift-and-coverage.md). This is now an implementation slice of the Reference Comparison loop, not a parallel design.

Resolves the documented ceiling in Scenarios::HandshakeCheck: `:required_after_submit` is checked as plain `:required` because nothing knows which step a run reached.

Once TASK-114 (Scenarios::SignatureKind) and TASK-116 (namespaced-marker diff + coverage/drift split) exist, HandshakeCheck consumes the same `step:` and `commitment_boundary:` vocabulary and distinguishes:

- required and present
- missing, but the required step was not reached — coverage information, not a failure
- missing after the required step was reached — drift / failure
- not applicable to this session purpose (e.g. a post-submit signature for an application_research session that intentionally stopped at the first commitment boundary)

Depends on TASK-114 for the kind value object and TASK-116 for the step/checkpoint model and the Reached Scope concept — nothing to be step-aware against otherwise.

Note: if the implementer of TASK-116 finds it more natural to land the HandshakeCheck change in the same PR as the ReferenceDiff change, that is acceptable — close this as absorbed and check TASK-116 accordingly. Kept as a separate slice because HandshakeCheck has its own existing spec surface and callers.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Scenarios::HandshakeCheck consumes step: and commitment_boundary: markers via Scenarios::SignatureKind and reports the four outcomes above per expected kind
- [x] #2 A scenario missing a required-after-a-step signature because it genuinely never reached that step is reported as coverage information, distinct from one where the signature is absent despite the step being reached (drift)
- [x] #3 A post-commitment-boundary signature is reported not-applicable for an application_research session that stopped at the boundary
- [x] #4 Existing Scenarios::HandshakeCheck spec coverage still passes for the bare-kind cases that already work correctly
- [x] #5 The :required_after_submit ceiling comment in handshake_check.rb is removed or updated to describe the step-aware behaviour
- [x] #6 Spec coverage for each of the four outcomes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Approach

Minimal, self-contained change to `app/services/scenarios/handshake_check.rb`. Step-awareness is needed only for the `:required_after_submit` level — plain `:required` / `:optional` are unchanged.

- `HandshakeCheck.call(scenario, purpose: nil)` — new optional kwarg (no caller passes it today, so no break).
- New status_for branch for `:required_after_submit`:
  - present → `required-and-present`
  - absent + the scenario has any `commitment_boundary:` signature (submit step reached) → `required-and-missing` (real drift/failure)
  - absent + no `commitment_boundary:` + `purpose == "application_research"` → `not-applicable-to-purpose` (the run intentionally stopped at the boundary)
  - absent + no `commitment_boundary:` + otherwise → `missing-step-not-reached` (coverage information, not a failure)
- "submit reached" = `observed_kinds.any? { Scenarios::SignatureKind.for(_1).namespace == "commitment_boundary" }`.
- Remove the `ponytail:` `:required_after_submit` ceiling comment in the file; replace with a one-liner pointing at ADR 009.

`SIGNATURE_EXPECTATIONS` stays as-is (`ats_application_id => :required_after_submit` for greenhouse is the only entry that exercises this).

## Specs
`spec/services/scenarios/handshake_check_spec.rb`:
- keep the linkedin/workday plain-kind tests (unchanged).
- replace the "checks required_after_submit as plain required (documented ceiling)" test with the four step-aware cases for greenhouse `ats_application_id`:
  present-and-boundary-reached, missing-and-boundary-reached (drift), missing-no-boundary-execution (`missing-step-not-reached`), missing-no-boundary-research (`not-applicable-to-purpose`).
- `capture_spec` HandshakeCheck cases are linkedin `job_id` (plain `:required`) — unaffected, must still pass.

## Verify
`bundle exec rspec spec/services/scenarios/handshake_check_spec.rb spec/services/scenarios/capture_spec.rb spec/services/scenarios/` + rubocop. Update `docs/architecture/signature-registry.md` "what exists" row for HandshakeCheck step-awareness.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Self-contained ~15-line change. `HandshakeCheck.call(scenario, purpose: nil)` — new optional kwarg, no existing caller passes it. Only `:required_after_submit` gains step-awareness; `:required` / `:optional` untouched.

after_submit_status(present): present -> required-and-present; absent + any commitment_boundary: signature observed -> required-and-missing (drift); absent + no boundary + purpose == "application_research" -> not-applicable-to-purpose; absent + no boundary otherwise -> missing-step-not-reached (coverage info).

"boundary reached" = observed_kinds.any? { Scenarios::SignatureKind.for(_1).namespace == "commitment_boundary" } -- the same vocabulary TASK-116's Coverage/DriftAnalysis use.

The old ponytail ceiling comment is gone; the class header now describes the step-aware behaviour and points at ADR 009.

Verification:
- spec/services/scenarios/handshake_check_spec.rb -- 4 new step-aware examples + the unchanged linkedin/workday plain-kind tests; capture_spec HandshakeCheck cases (linkedin job_id, plain :required) unaffected -> 20 examples, 0 failures.
- Full spec/services/scenarios + docs_spec -> 65 examples, 0 failures. RuboCop clean.
- signature-registry.md "what exists" row updated.
<!-- SECTION:NOTES:END -->

## Comments

<!-- COMMENTS:BEGIN -->
created: 2026-08-27 22:17
---
New domain context: step-aware handshake results should align with pump-track phases and distinguish required, optional, recommended, reversible, and approval-gated transitions when the guided session recorder exists (TASK-112).
---

author: wayfinder
created: 2026-08-29 00:21
---
Rewritten per ADR 009 and the wayfinder drift-loop map. Was: 'Make HandshakeCheck step-aware by comparing against the Reference Scenario' as an independent low-priority enhancement. Now a dependent implementation slice of the Reference Comparison loop (TASK-114 -> TASK-116 -> here). Old dependency on TASK-106 is subsumed by TASK-116.
---
<!-- COMMENTS:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
## What changed

`Scenarios::HandshakeCheck` is now step-aware for `:required_after_submit` (the documented ceiling, per ADR 009). ~15 lines; `:required` / `:optional` unchanged.

`call(scenario, purpose: nil)` — a missing post-submit signature (`ats_application_id` for Greenhouse) resolves to one of four statuses:
- `required-and-present` — observed
- `required-and-missing` — absent, but a `commitment_boundary:` was reached → real drift/failure
- `missing-step-not-reached` — absent, no boundary reached → coverage information, not a failure
- `not-applicable-to-purpose` — absent, no boundary, `purpose == "application_research"` → the run intentionally stopped there

"Boundary reached" uses the same `Scenarios::SignatureKind` namespace check as TASK-116's `Coverage` / `DriftAnalysis`. The old ceiling comment is replaced with a step-aware description pointing at ADR 009.

## Tests
`handshake_check_spec` — 4 new step-aware examples replacing the "checks as plain required (ceiling)" test; linkedin/workday plain-kind tests and the `capture_spec` HandshakeCheck cases (linkedin `job_id`, plain `:required`) unchanged and green → 20 examples, 0 failures. Full `spec/services/scenarios` + `docs_spec` → 65, 0. RuboCop clean.

## Follow-ups
Only **TASK-118** (rebuild the sandbox Greenhouse Reference Scenario — needs a browser dogfood) and **TASK-119** (trigger + review-page UI, closes TASK-112 AC#6) remain on the drift-loop map.
<!-- SECTION:FINAL_SUMMARY:END -->
