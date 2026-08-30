---
id: TASK-133
title: Guided-session deterministic replay execution
status: To Do
assignee: []
created_date: '2026-08-30 15:08'
labels:
  - application-workflow
  - human-in-the-loop
  - application-capture-datalake
dependencies:
  - TASK-112
references:
  - app/services/guided_sessions/replay_plan.rb
  - docs/architecture/guided-session-flow.md
  - >-
    backlog/tasks/task-112 -
    Phase-B-guided-application-session-recorder-with-supervised-intent.md
priority: medium
type: feature
ordinal: 149000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The execution half of TASK-112 AC#5. `GuidedSessions::ReplayPlan` already produces the read-only plan (which recorded steps a replay would auto-advance vs pause on). This task is the part that actually re-drives a browser through the deterministic steps and stops for Mike at every gate.

**This is a Bounded Agency decision, not a mechanical follow-up.** It is the first thing in the system that would fill a real form field on an employer site. It must be scoped with Mike before any build:
- What "auto-advance a deterministic step" means concretely (re-fill known fields from the recorded mapping? click a known "Next"? nothing that transmits?).
- Whether replay ever touches a real employer site or only the sandbox.
- The explicit start gesture, the visible "replay is running" state, and the hard stop at every `ReplayPlan` gate.
- How an approved commitment boundary resumes (the open question `guided-session-flow.md` names).

## Out of scope until scoped
- Any auto-submit. Final submission stays a `User Task` always.
- Consuming a readiness class / eval score to skip a review prompt during replay.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Scoped with Mike before implementation: what a deterministic step re-executes, sandbox-only vs real sites, the start gesture and running-state UI, and the resume-after-approval mechanism
- [ ] #2 A replay pauses at every GuidedSessions::ReplayPlan gate and cannot advance past one without an explicit Mike action
- [ ] #3 Final application submission is never auto-executed
- [ ] #4 A test proves a replay cannot cross a commitment boundary or submit without explicit approval
<!-- AC:END -->
