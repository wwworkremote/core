---
id: TASK-32.5
title: Generalize management-tier filter into role-family filtering in JobPostings UI
status: To Do
assignee: []
created_date: '2026-08-08 15:50'
labels: []
milestone: m-0
dependencies:
  - TASK-32.3
parent_task_id: TASK-32
priority: medium
type: enhancement
ordinal: 36000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Goal: replace the single binary `management_tier` scope and `@tier == "management"` filter (app/models/job_posting.rb, app/controllers/job_postings_controller.rb) with filtering by any role family from the task-32.3 taxonomy, so users can filter/browse postings by role family (e.g. "staff-plus IC", "engineering management") instead of only a management/non-management toggle.

Depends on task-32.3 (role-family taxonomy map): this task consumes that task's lookup API to build the filter scope. Do not start until task-32.3 is Done.

Scope: JobPosting scope + JobPostingsController + the minimal view change needed to expose the new filter option(s) to match how the existing management-tier toggle is currently exposed. Do not redesign the broader JobPostings UI/filtering panel beyond what's needed to add role-family selection alongside (or replacing) the existing tier toggle.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 JobPosting supports filtering by any role family defined in task-32.3's taxonomy, not just a management/non-management binary
- [ ] #2 The existing management-tier filter's user-visible behavior is preserved or has a clear equivalent under the new role-family filtering (no silent loss of the current filter option)
- [ ] #3 RSpec/request-spec coverage exercises filtering by at least two different role families and confirms postings outside any selected family are excluded
- [ ] #4 Full RSpec suite passes
<!-- AC:END -->
