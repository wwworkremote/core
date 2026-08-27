---
id: TASK-95
title: >-
  Docs viewer with Mermaid diagrams for system architecture and the application
  pipeline
status: In Progress
assignee:
  - claude
created_date: '2026-08-26 23:40'
labels: []
dependencies: []
references:
  - TASK-82
  - TASK-94
priority: medium
type: feature
ordinal: 110000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Mike wants a navigable documentation surface inside the app itself (not just files in the repo) covering how the system works and how the job application pipeline works, with real diagrams (component/collaboration, sequence, state/statechart) rather than prose alone -- this is meant to function as a knowledge system, not a one-off writeup. He independently arrived at "this looks like a state machine / BPMN problem" and wants that formalized visually, tying into TASK-82 (the JobPosting/UserJobPosting status split) and TASK-94 (the statechart prior-art spike).

The repo already has a substantial docs/ tree (23 markdown files: architecture.md, development.md, ADRs, agent guides) with no way to browse it from the running app -- only via git/editor. Redcarpet (markdown-to-HTML) is already a Gemfile dependency.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A route in the app renders the existing docs/ markdown tree, navigable without leaving the browser
- [ ] #2 Diagrams embedded in those markdown files (Mermaid syntax) render as actual diagrams in the browser, not as raw text/code blocks
- [ ] #3 New diagram content exists covering: the major system components and how they collaborate (Rails app, Chrome extension, ingestion sources, pipeline/audit log), the UserJobPosting/JobPosting pipeline as a state diagram (reflecting the TASK-82 split: posting lifecycle vs user pipeline stage vs employer outcome), and a sequence diagram of the actual application flow (ingestion through triage through apply through outcome)
- [ ] #4 The docs surface is reachable from the app's normal navigation, not just a URL Mike has to remember
- [ ] #5 Rendering is restricted to the known docs directory -- no arbitrary file path can be read from a URL parameter
<!-- AC:END -->
