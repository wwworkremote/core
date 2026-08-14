---
id: TASK-37.6
title: >-
  Reconcile docs/extension-workflow.md and OpenAPI spec with final pipeline
  state
status: To Do
assignee: []
created_date: '2026-08-13 17:42'
labels: []
milestone: m-1
dependencies: []
parent_task_id: TASK-37
priority: low
type: docs
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A prior session's worth of fixes landed without a final documentation pass: retry/backoff on apiFetch, an Ahoy-based "Captured Lead" observability event with a per-provider capture-health rollup on `/admin/extension_workflow`, a toolbar badge for supported-board detection, a Geo::CommuteZone bug fix (it checked the wrong data key for "is this posting remote", so a real remote posting could get auto-hidden), a JSON-LD feed-contamination guard, and the ATS provider fixes tracked in this task's sibling subtasks. Do this last, after TASK-37.1 through TASK-37.5 have landed, or it will need to be redone -- it's meant to describe final state, not a snapshot mid-flight.

`docs/extension-workflow.md` is rendered live (via Redcarpet + client-side Mermaid) at `/admin/extension_workflow` -- check the rendered page, not just the source markdown, since diagram syntax errors only show up there.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 docs/extension-workflow.md's component table, sequence diagrams, and entity/contract sections accurately describe the current code (re-read the actual files, don't assume prior doc content is still accurate)
- [ ] #2 The "Known fragility" section reflects everything found across TASK-37.1 through TASK-37.5, not just what was known when the doc was last touched
- [ ] #3 docs/architecture/openapi.yaml matches the current request/response shapes for every /api/* endpoint the extension calls
- [ ] #4 The existing request spec for GET /admin/extension_workflow (spec/requests/admin/extension_workflow_spec.rb) still passes after the doc update
- [ ] #5 The rendered page at /admin/extension_workflow is visually checked (mermaid diagrams render without syntax errors, no missing sections)
<!-- AC:END -->
