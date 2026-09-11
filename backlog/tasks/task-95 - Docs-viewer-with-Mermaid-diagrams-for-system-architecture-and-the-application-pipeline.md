---
id: TASK-95
title: >-
  Docs viewer with Mermaid diagrams for system architecture and the application
  pipeline
status: Done
assignee:
  - claude
created_date: '2026-08-26 23:40'
updated_date: '2026-08-27 00:00'
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
- [x] #1 A route in the app renders the existing docs/ markdown tree, navigable without leaving the browser
- [x] #2 Diagrams embedded in those markdown files (Mermaid syntax) render as actual diagrams in the browser, not as raw text/code blocks
- [x] #3 New diagram content exists covering: the major system components and how they collaborate (Rails app, Chrome extension, ingestion sources, pipeline/audit log), the UserJobPosting/JobPosting pipeline as a state diagram (reflecting the TASK-82 split: posting lifecycle vs user pipeline stage vs employer outcome), and a sequence diagram of the actual application flow (ingestion through triage through apply through outcome)
- [x] #4 The docs surface is reachable from the app's normal navigation, not just a URL Mike has to remember
- [x] #5 Rendering is restricted to the known docs directory -- no arbitrary file path can be read from a URL parameter
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built `/docs` (DocsController + DocsMarkdownRenderer), browsing the existing docs/**/*.md tree with Mermaid diagrams rendered as real SVGs, not code blocks. Added three new diagram docs under docs/architecture/: component-overview.md (flowchart of how the major pieces collaborate), pipeline-statechart.md (three independent stateDiagram-v2 blocks: JobPosting lifecycle, UserJobPosting pipeline stage, UserJobPosting outcome -- ties directly into TASK-82), and application-sequence.md (one posting's full journey as a sequenceDiagram, referencing TASK-91/91.2/93 as the not-yet-built next links). "Docs" added to primary nav.

Path-traversal guarded (verified real-path expansion, not string-prefix matching) and covered by spec/requests/docs_spec.rb, including a nested-segment traversal attempt.

Two real bugs only surfaced by loading the pages, not writing careful code: Rails deriving request.format from the .md extension in the raw path independently of routing (fixed with an explicit request.format = :html before_action), and a literal Mermaid syntax error from a "::" inside an unquoted stateDiagram-v2 label (fixed the label text, and separately switched mermaid.run to suppressErrors: true so one bad diagram can't blank the whole page again).

All 4 diagrams (2 state, 1 flowchart, 1 sequence) confirmed rendering as actual SVGs in a real browser across all three doc pages. 14 specs green, rubocop/erb_lint clean. Commit ec65f54b.
<!-- SECTION:FINAL_SUMMARY:END -->
