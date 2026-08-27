---
id: TASK-106
title: 'Reference Scenario: marking, storage, and the manual promotion workflow'
status: To Do
assignee: []
created_date: '2026-08-27 17:25'
labels:
  - architecture
  - signature-registry
dependencies:
  - TASK-102
documentation:
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
