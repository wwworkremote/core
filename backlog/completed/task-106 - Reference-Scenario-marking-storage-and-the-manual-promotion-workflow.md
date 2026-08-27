---
id: TASK-106
title: 'Reference Scenario: marking, storage, and the manual promotion workflow'
status: Done
assignee:
  - '@mike'
created_date: '2026-08-27 17:25'
updated_date: '2026-08-27 22:05'
labels:
  - architecture
  - signature-registry
dependencies:
  - TASK-102
documentation:
  - docs/architecture/signature-registry.md
modified_files:
  - db/migrate/20260827200000_create_reference_scenarios.rb
  - db/schema.rb
  - app/models/reference_scenario.rb
  - app/models/scenario.rb
  - app/services/scenarios/reference_diff.rb
  - app/services/scenarios/promote_reference.rb
  - lib/tasks/scenarios.rake
  - spec/factories/scenarios.rb
  - spec/models/reference_scenario_spec.rb
  - spec/services/scenarios/reference_diff_spec.rb
  - spec/services/scenarios/promote_reference_spec.rb
  - docs/architecture/signature-registry.md
priority: medium
type: feature
ordinal: 500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
docs/architecture/signature-registry.md, "Reference Scenario -- the golden master, not a 'platonic ideal'" section, plus the "Decided" and "Open questions" sections -- read all three before starting.

A Reference Scenario is an ordinary Scenario row whose ScenarioSignatures, in order, are the current best-understood correct sequence for a provider -- one per provider. Needs: (1) a way to mark/look up "the current reference Scenario for provider X" (open question in the doc -- boolean flag on Scenario vs. a separate one-row-per-provider pointer table, explicitly called low-stakes/implementer's-call, not worth another round-trip with Mike), (2) a promotion workflow.

Promotion is DECIDED, not open: always requires Mike to look at the diff first (docs/architecture/signature-registry.md, "Decided" section, 2026-08-27). No auto-promote on a clean guided run, ever. Build whatever review surface makes that diff visible (could be as simple as a rake task or console helper printing the diff between a candidate Scenario and the current reference -- doesn't need a full UI unless that's clearly warranted once this is in hand).

Depends on TASK-102 (capture path) -- no real Scenario data to mark as a reference without it.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A Scenario can be marked/looked-up as 'the current reference for provider X', one per provider
- [ ] #2 Chosen mechanism (flag vs. pointer table) is documented with brief reasoning
- [ ] #3 A tool exists (rake task, console helper, or similar) that shows the diff between a candidate Scenario and the current reference for its provider, in terms of ScenarioSignature kinds gained/lost/reordered
- [ ] #4 No code path promotes a Scenario to reference status without an explicit, separate action -- a clean matching run alone never changes what's marked as reference
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Read the signature-registry decisions and existing Scenario conventions.
2. Add a one-row-per-provider ReferenceScenario pointer with a database uniqueness invariant and document the choice.
3. Build a small ReferenceDiff module reporting gained, lost, and reordered ScenarioSignature kinds.
4. Add an explicit promotion command/task that requires a candidate and prints or returns the diff before writing the pointer.
5. Add focused model/service/task specs proving lookup, diff semantics, and no implicit promotion.
6. Run focused checks, inspect the diff, and commit without pushing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Selected a separate ReferenceScenario pointer table rather than a boolean Scenario flag: it keeps captured Scenario rows immutable, makes one-reference-per-provider enforceable with a unique provider index, and leaves promotion as a distinct explicit action.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented manual Reference Scenario management. Added a database-enforced one-row-per-provider ReferenceScenario pointer, read-only Scenarios::ReferenceDiff reporting ordered candidate/reference sequences plus gained/lost/reordered kinds, and explicit Scenarios::PromoteReference promotion. Added preview-first rake task scenarios:reference_diff[TOKEN], with PROMOTE=1 as the separate write action. Updated signature-registry architecture documentation. Focused suite: 26 examples, 0 failures. Commit: e4ba7c2f.
<!-- SECTION:FINAL_SUMMARY:END -->
