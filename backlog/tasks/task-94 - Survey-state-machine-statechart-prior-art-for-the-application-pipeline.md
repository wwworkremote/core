---
id: TASK-94
title: Survey state-machine/statechart prior art for the application pipeline
status: Done
assignee:
  - claude
created_date: '2026-08-26 23:10'
updated_date: '2026-08-27 00:14'
labels: []
dependencies: []
references:
  - TASK-82
  - TASK-91
  - TASK-91.2
  - TASK-93
priority: low
type: spike
ordinal: 109000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Mike observed that the job-search pipeline (lead -> posting -> application -> offer/decline, with a company re-entering consideration once its cooldown expires — see TASK-91.2) resembles well-established state-machine / workflow-modeling problems rather than something to design ad hoc from scratch, and suspects there's prior art (state machines, statecharts, BPMN, or similar) that should inform the design.

This app already uses AASM (a Ruby state-machine gem) in two places that have drifted apart — see TASK-82 (JobPosting.status vs UserJobPosting.status, 25 rows disagree, no reconciliation yet). Before more pipeline work compounds that inconsistency, this spike should research how established state-machine/statechart concepts — composite/nested states, re-entrant transitions (a company's cooldown expiring), timeout-triggered transitions (matching TASK-93's "notify after N idle days") — would map onto this app's actual states, and recommend a direction.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A written summary of relevant prior art/concepts (state machines, statecharts, BPMN, or similar) as they apply to this specific pipeline: lead/posting/application/company, including cooldown re-entry and idle-timeout notification
- [x] #2 A recommendation for whether and how to consolidate the app's pipeline representation onto a single formal state machine, referencing TASK-82's existing findings
- [x] #3 No code changes as part of this task — findings feed future implementation tasks
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Desk research against this app's actual code (already mapped via TASK-82), not a general literature survey. Writing findings straight into notes/finalSummary since AC #3 explicitly forbids code changes.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Prior art survey

**UML/Harel statecharts.** The relevant concept is orthogonal (concurrent) regions: one entity can be in several independent states at once, each with its own transition graph. That's exactly TASK-82's three axes (JobPosting lifecycle / UserJobPosting stage / UserJobPosting outcome) -- Mike re-derived a real statechart concept independently. The other Harel concept that matters: timeout-triggered transitions (a state has a deadline; no event before it fires an automatic transition). That's a direct match for TASK-93 ("no PipelineStep in 2-3 days -> notify").

**CRM opportunity pipelines (Salesforce et al).** Same stage-vs-disposition split: StageName (funnel position) is independent of IsWon/IsClosed (outcome, settable at any stage). Already the model TASK-91 follows.

**BPMN.** Built for multi-actor, cross-system business processes -- pools/lanes per organization, gateways for parallel/conditional branching, boundary timer events for SLA-style deadlines. The "many sources aggregate leads" fan-in and the idle-notification deadline are BPMN-native shapes, but BPMN's actual payoff (visual process handoff between departments/roles) doesn't apply here: it's one user acting through two tools (Rails app, extension), not a multi-party handoff. Standing up a BPMN engine (Camunda etc.) for a single-user tool would be pure overhead with no one else to hand a swimlane to.

## Recommendation

1. **Don't unify into one state machine or adopt a workflow engine.** Three independent AASM machines (posting lifecycle, pipeline stage, outcome), coordinated through the existing shared PipelineStep audit log, is already the right-sized answer -- it's a plain-Ruby implementation of the orthogonal-regions concept without the ceremony of a general statechart library neither AASM nor this app's scale needs.
2. **Concrete action for TASK-82 phase 3:** move `offered` off UserJobPosting.status (a stage) onto outcome (a disposition), alongside `rejected` -- this was Mike's own live correction during phase 1 and this survey confirms it's the right call, not just a naming preference: 'offered' is the employer's decision, the same kind of fact as 'rejected', not a stage Mike walks through like 'applied'/'interview' are.
3. **Company cooldown re-entry (TASK-91.2) and idle notification (TASK-93) don't need any new pattern.** Both are plain scheduled-job timestamp comparisons (last_denied_on + 6mo elapsed; no PipelineStep in 2-3 days) -- the Harel 'timeout transition' concept names what they're doing, it doesn't imply they need special infrastructure to implement.

No code changed as part of this task, per AC #3.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Recommendation: keep three independent AASM machines (posting lifecycle, pipeline stage, outcome) coordinated via PipelineStep -- don't unify into one statechart or adopt a workflow engine, this app's scale doesn't need it. Concrete finding for TASK-82 phase 3: move `offered` off status onto outcome, alongside `rejected` (Mike's own live correction, confirmed by the CRM-pipeline precedent). TASK-91.2 and TASK-93's "cooldown expiry" and "idle notification" are plain scheduled-job timestamp checks, not a pattern requiring new infrastructure. Full survey in notes. No code changed.
<!-- SECTION:FINAL_SUMMARY:END -->
