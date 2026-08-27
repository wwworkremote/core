---
id: TASK-109
title: >-
  Ground Reference Scenario in common ATS states/systems, build the
  visualization model
status: To Do
assignee: []
created_date: '2026-08-27 17:50'
updated_date: '2026-08-27 22:17'
labels:
  - architecture
  - signature-registry
dependencies:
  - TASK-106
references:
  - TASK-112
documentation:
  - docs/architecture/panoramic-view.md
  - docs/architecture/signature-registry.md
priority: low
type: task
ordinal: 800
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
docs/architecture/panoramic-view.md, "Visualization model" section (captured 2026-08-27) -- read it first, it has the full model.

Two related follow-ups flagged in conversation, not yet built:

1. Ground the Reference Scenario concept (docs/architecture/signature-registry.md) in job-application workflow patterns that are common knowledge, not just the 4 providers directly observed so far (LinkedIn, Greenhouse, Indeed, Workday). Common ATS states: applied, screening, phone screen, interview loop, offer, rejected, withdrawn. Common system shapes beyond the four already named: Lever, iCIMS, Taleo, SmartRecruiters. This wasn't invented from nothing -- don't design each Reference Scenario's expected shape as if the provider were unprecedented when it isn't.

2. Build the visualization model into an actual rendered view: left-to-right = actor's journey (starting state, persona/goals, success/failure criteria), vertical = depth through the topology per step (the capture/orchestrated/platform lanes already named in panoramic-view.md, not a generic call stack) as a sinusoidal wave with async/fire-and-forget calls branching off the main wave, and multiple point-in-time snapshots stacked along time and distance to reconstruct a volumetric model of one traced run (CT/MRI-style slice stacking).

Depends on TASK-106 (Reference Scenario storage) existing -- nothing concrete to visualize or ground against before that.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Reference Scenario expected-shape design references at least the additional common ATS systems named above, not just the 4 already directly observed
- [ ] #2 A rendered (not just designed) view exists showing at least the left-to-right actor-journey axis for one real traced Scenario
- [ ] #3 The vertical/topology-lane dimension from the visualization model is represented in that view in some form -- full sinusoidal rendering is not required for this task to be considered done, a first pass that captures the two axes is sufficient
<!-- AC:END -->

## Comments

<!-- COMMENTS:BEGIN -->
created: 2026-08-27 22:17
---
New domain context from the pump-track ADR: the visualization should render a supervised application lap across Intake, Resolution, Response Construction, and Reorientation, with approval gates and intent annotations visible at transitions. The first Phase B recorder is now tracked as TASK-112; this task should consume its recorded session timeline rather than inventing a parallel capture model.
---
<!-- COMMENTS:END -->
