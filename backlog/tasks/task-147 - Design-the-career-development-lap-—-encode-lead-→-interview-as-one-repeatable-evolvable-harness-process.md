---
id: TASK-147
title: >-
  Design: the career-development lap — encode lead → interview as one
  repeatable, evolvable harness process
status: To Do
assignee: []
created_date: '2026-09-03 03:36'
labels:
  - architecture
  - job-search
dependencies: []
priority: medium
type: spike
ordinal: 167000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Today the arc from lead to interview prep is three connected-but-separate layers, not one encoded process:

1. Lifecycle spine (exists, repeatable): UserJobPosting.status AASM (favorited -> applied -> interviewing -> offer) + PipelineStep append-only audit per (user, posting) + Lead -> guided_sessions#create_from_posting.
2. Application step (recorded AND evolvable): the harness -- GuidedSession records a supervised application lap into the Datalake, materializes a Scenario, ReferenceComparison diffs it against the provider ReferenceScenario -> Finding -> Disposition. Only covers submitting on an ATS.
3. Interview prep + interview (NOT in the harness): the prep pack is a standalone artifact on a UserJobPosting column -- no GuidedSession, no PipelineStep, no reference comparison. InterviewSession/InterviewQuestion/InterviewTask exist but are thin, unlinked to the pack, with no recording of the interview or an outcome -> strategy feedback loop.

The question (raised 2026-09-02): can the whole arc be mapped end to end, repeatable and evolvable, in the recording harness -- as a career-development tool, not just a job-application tool?

The ingredients are there: the Pump Track is already the conceptual frame; PipelineStep is the spine; the ReferenceScenario/ReferenceComparison pattern generalizes to a "reference career-development lap" per role archetype.

Deliverable: an ADR + a sequenced plan (not an implementation). Cover:
- PipelineStep step types for the prep and interview phases (pack generated / reviewed / approved; interview scheduled / held / debriefed).
- Link InterviewSession <-> the prep pack <-> the posting.
- Outcome -> strategy feedback (rejection_reason + company cooldown from TASK-91 are a partial start).
- Whether a "reference lap" per role archetype is worth building for run-over-run comparison, or whether the Pump Track + PipelineStep audit is enough.
- What stays a standalone artifact vs what becomes a recorded, comparable lap.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 An ADR proposing (or rejecting) the career-development lap as a generalization of the harness pattern
- [ ] #2 A dependency-ordered plan of the concrete changes, referencing real models (PipelineStep, InterviewSession, UserJobPosting, ReferenceScenario)
- [ ] #3 A clear line on what is recorded/comparable vs what stays a standalone artifact
- [ ] #4 No implementation -- design only
<!-- AC:END -->
