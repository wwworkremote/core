---
id: TASK-107
title: Step-aware HandshakeCheck against ADR-009 markers
status: To Do
assignee: []
created_date: '2026-08-27 17:25'
updated_date: '2026-08-29 00:21'
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
- [ ] #1 Scenarios::HandshakeCheck consumes step: and commitment_boundary: markers via Scenarios::SignatureKind and reports the four outcomes above per expected kind
- [ ] #2 A scenario missing a required-after-a-step signature because it genuinely never reached that step is reported as coverage information, distinct from one where the signature is absent despite the step being reached (drift)
- [ ] #3 A post-commitment-boundary signature is reported not-applicable for an application_research session that stopped at the boundary
- [ ] #4 Existing Scenarios::HandshakeCheck spec coverage still passes for the bare-kind cases that already work correctly
- [ ] #5 The :required_after_submit ceiling comment in handshake_check.rb is removed or updated to describe the step-aware behaviour
- [ ] #6 Spec coverage for each of the four outcomes
<!-- AC:END -->

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
