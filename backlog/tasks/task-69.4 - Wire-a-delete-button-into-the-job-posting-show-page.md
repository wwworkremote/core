---
id: TASK-69.4
title: Wire a delete button into the job posting show page
status: To Do
assignee: []
created_date: '2026-08-19 01:58'
labels: []
dependencies: []
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
