---
id: TASK-66.3
title: Show job posting change history on the job posting page
status: To Do
assignee: []
created_date: '2026-08-17 23:13'
updated_date: '2026-08-17 23:14'
labels:
  - ux
  - job-postings
dependencies:
  - TASK-66.1
parent_task_id: TASK-66
type: feature
ordinal: 74000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Part of TASK-66, targets the unified page from the view-merge subtask. JobPosting already declares `has_paper_trail` (app/models/job_posting.rb:14) and PaperTrail is actively recording versions on every save -- confirmed non-empty `versions` table in dev, including changes made by JobBoards::Reformatter/JobPostingReformatJob (the AI description-reformatting flow). There is currently no view anywhere that renders `job_posting.versions`.

Add a change-history panel to the job posting page showing what changed, when, and (where available) what triggered it -- e.g. a reformat job run, a manual edit, an enrichment pass. PaperTrail's `whodunnit` is likely blank for system/job-triggered changes (no request context), so the display should degrade gracefully to "system" or the job/process name rather than a blank attribution, using whatever PaperTrail metadata (event type, object_changes) is actually available rather than assuming a user is always behind each version.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Job posting page shows a chronological list of recorded versions (create/update events) with timestamps
- [ ] #2 Each entry shows what changed in human-readable form (not raw serialized diff), using PaperTrail's object_changes
- [ ] #3 Versions with no whodunnit (system/job-triggered changes) display sensibly rather than blank or erroring
- [ ] #4 History is reachable without leaving the job posting page (inline panel, tab, or modal -- not a separate top-level route)
<!-- AC:END -->
