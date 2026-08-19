---
id: TASK-69.2
title: >-
  Exclude flagged sources/companies from job postings index, company page, and
  source page
status: To Do
assignee: []
created_date: '2026-08-19 01:58'
labels: []
dependencies:
  - TASK-69.1
parent_task_id: TASK-69
priority: high
type: feature
ordinal: 80000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Once TASK-69.1 lands the results-exclusion flag on `JobBoards::Source`, apply it as a default scope/exclusion everywhere job postings are listed: `JobPostingsController#index`, `CompaniesController#show`, and the source-scoped view (`job_postings_path(source_id: ...)` per `app/views/job_postings/index.html.erb:177`). Also add the equivalent "exclude everything from this source/company" bulk action already patterned by `Admin::CompaniesController#mark_not_interested` (`app/controllers/admin/companies_controller.rb:17-29`) — but as results-exclusion (not ingestion-disable, not purge) for the source case, mirroring what TASK-69.1 built.

Once this ships, flip ArbeitNow's flag on `/admin/sources/17` as the immediate real-world trigger case.
<!-- SECTION:DESCRIPTION:END -->
