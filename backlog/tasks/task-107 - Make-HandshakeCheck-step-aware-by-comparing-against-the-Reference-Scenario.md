---
id: TASK-107
title: Make HandshakeCheck step-aware by comparing against the Reference Scenario
status: To Do
assignee: []
created_date: '2026-08-27 17:25'
updated_date: '2026-08-27 17:26'
labels:
  - architecture
  - signature-registry
dependencies:
  - TASK-106
documentation:
  - docs/architecture/signature-registry.md
  - app/services/scenarios/handshake_check.rb
priority: low
type: enhancement
ordinal: 600
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Resolves the documented ceiling in Scenarios::HandshakeCheck (app/services/scenarios/handshake_check.rb): ':required_after_submit is checked as plain :required for now -- this doesn't yet know which step a scenario reached, only which kinds it observed.'

Once a Reference Scenario exists per provider (TASK-106) with real ordered ScenarioSignatures, HandshakeCheck (or a sibling service) can compare a candidate Scenario's signatures-with-steps against the reference's actual sequence, instead of the current flat SIGNATURE_EXPECTATIONS hash -- so 'required after submit' becomes a real position in a real sequence rather than an unenforced label.

Depends on TASK-106 (Reference Scenario marking/storage) existing first -- nothing to compare against otherwise. Low priority: the current flat-hash HandshakeCheck already works correctly for every case except the specific required_after_submit distinction, so this is a precision upgrade, not a blocker for anything else in this plan.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A scenario missing a required_after_submit signature because it genuinely never reached that step is distinguished from one where the signature is simply absent
- [ ] #2 Existing Scenarios::HandshakeCheck spec coverage still passes -- this is a precision upgrade, not a behavior change for the kinds that already work correctly
- [ ] #3 The documented ceiling comment in handshake_check.rb is removed or updated to reflect the new step-aware behavior
<!-- AC:END -->
