---
id: TASK-94
title: Survey state-machine/statechart prior art for the application pipeline
status: To Do
assignee: []
created_date: '2026-08-26 23:10'
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
- [ ] #1 A written summary of relevant prior art/concepts (state machines, statecharts, BPMN, or similar) as they apply to this specific pipeline: lead/posting/application/company, including cooldown re-entry and idle-timeout notification
- [ ] #2 A recommendation for whether and how to consolidate the app's pipeline representation onto a single formal state machine, referencing TASK-82's existing findings
- [ ] #3 No code changes as part of this task — findings feed future implementation tasks
<!-- AC:END -->
