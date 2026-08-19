---
id: TASK-69.4
title: Wire a delete button into the job posting show page
status: Done
assignee: []
created_date: '2026-08-19 01:58'
updated_date: '2026-08-19 12:00'
labels: []
dependencies: []
modified_files:
  - app/views/job_postings/show.html.erb
  - config/locales/en.yml
  - spec/requests/job_postings_spec.rb
  - spec/requests/admin/job_postings_spec.rb
parent_task_id: TASK-69
priority: medium
type: bug
ordinal: 82000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`Admin::JobPostingsController#destroy` (hard delete) already exists and is routed (`app/controllers/admin/job_postings_controller.rb:61-65`), but no view has a button for it — only the bulk "Delete Permanently" trash action reaches it (`app/views/admin/job_postings/index.html.erb:29`). Add a real delete action to `app/views/job_postings/show.html.erb` (public+admin were merged in TASK-66.1). Confirm destructively via `data-turbo-confirm` per this app's existing pattern (see the "Mark all not interested" button in `app/views/job_postings/index.html.erb:91`).

Trigger case: `/job_postings/5052` has no delete option today.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added "Delete Permanently" next to the existing Restore button in the Application Status panel -- shown only once a posting is purged (`may_restore?`), mirroring the admin index's existing "only offer hard delete from the trash" convention. Hits the pre-existing `Admin::JobPostingsController#destroy` route, which had zero callers in any view before this (only bulk-delete-from-trash reached it).

- `data-turbo-confirm` guard, matching the existing Purge button's pattern.
- Verified live: the real "test" placeholder posting at /job_postings/5052 (fake data, its own AI match analysis flagged it "not real -- skip this posting") now renders the button correctly, gated behind purged status.
- Along the way found the dev server on :31000 had gone unresponsive (504/timeout) -- restarted cleanly, unrelated to this change.
- 2 new spec examples (button visibility gated on purge state; the destroy route itself, which had no direct request spec before). Full suite: 630+ examples, 0 failures.

This closes out TASK-69 (parent) -- all four subtasks (69.1-69.4) done.
<!-- SECTION:FINAL_SUMMARY:END -->
