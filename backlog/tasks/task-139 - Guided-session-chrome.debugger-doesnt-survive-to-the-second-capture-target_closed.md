---
id: TASK-139
title: >-
  Guided-session chrome.debugger doesn't survive to the second capture
  (target_closed)
status: To Do
assignee: []
created_date: '2026-08-30 23:37'
labels:
  - extension
  - datalake
  - application-workflow
dependencies: []
references:
  - backlog/tasks/task-134 -
  - >-
    backlog/tasks/task-126 -
    Guided-session-raw-asset-capture-into-the-datalake.md
priority: medium
type: bug
ordinal: 155000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found in the first real-browser dogfood of the guided-session capture loop (extension 1.36.0, local /sandbox ATS, 2026-08-30).

In an `application_execution` guided session:
- 1st capture (`application_page_arrived`, on load): DOM + HAR + full-page CDP screenshot, zero gaps. chrome.debugger attached cleanly.
- 2nd capture (`submission_attempted`, ~49s later, same page, no navigation): DOM captured, but HAR and screenshot both gap with reason `"target_closed"`.

`captureExecutionArtifacts` re-sends `GUIDED_DEBUGGER_ATTACH` before every capture, so the re-attach path ran and still hit `target_closed` on the subsequent CDP `sendCommand`. Likely cause: the background service worker went idle between captures and lost the in-memory `guidedDebugger` Map / attach state (the known ceiling called out in TASK-134), and re-attach didn't fully recover; or Chrome auto-detached the debugger.

IMPORTANT CONFOUND: the dogfood was driven via Claude-in-Chrome, which itself uses CDP/the debugger to inject input and screenshot. There was debugger contention a real hands-on session would not have. This needs a human-hands retest (start an execution session, arrive on the app page, wait ~1 min, trigger a second transition, check the manifest) before treating the SW-idle theory as confirmed. If it reproduces without the automation harness, the fix is likely persisting attach state (chrome.storage.session) + a robust re-attach, or keeping the SW alive for the session's duration.

The degradation itself worked correctly: the failures became gaps, the session continued, the DOM still captured — TASK-126 AC#7 behaviour holds.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Reproduce (or fail to reproduce) the target_closed gap in a hands-on execution session with no automation harness attached, and record the result
- [ ] #2 If it reproduces: the chrome.debugger attach survives across multiple captures in one guided session, or re-attaches transparently, so HAR + full-page screenshot land on every execution transition (not just the first)
- [ ] #3 docs/architecture/datalake.md 'known ceilings' updated with the confirmed behaviour
<!-- AC:END -->
