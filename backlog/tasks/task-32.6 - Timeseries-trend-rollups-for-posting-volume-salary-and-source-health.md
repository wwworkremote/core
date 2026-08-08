---
id: TASK-32.6
title: 'Timeseries trend rollups for posting volume, salary, and source health'
status: To Do
assignee: []
created_date: '2026-08-08 15:50'
labels: []
milestone: m-0
dependencies: []
parent_task_id: TASK-32
priority: low
type: feature
ordinal: 37000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Goal: this codebase has no timeseries/trend capability today (no TimescaleDB, no rollup or materialized views), despite being rich in time-series-shaped data -- job posting volume over time, salary drift, per-source ingestion health (JobBoards::Source has `last_ingested_at`; SolidQueue job history has timestamps). `SystemInsight` (app/models/system_insight.rb, has an embedding column and an `active`/`file_path` shape) looks like it was built toward surfacing exactly this kind of insight but nothing currently populates trend data into it or anywhere else.

This is the lowest-dependency-count but most net-new capability in the audit -- no existing extension needs adopting (Postgres's built-in `date_trunc` + a materialized view, refreshed on a schedule, is sufficient; do not add TimescaleDB or any new extension for this).

Scope: pick a small, concrete first trend (recommend: weekly job-posting volume per role-family/category and per source) rather than building a general trend framework speculatively. Do not attempt to cover salary drift AND source health AND posting volume in one task -- ship one real trend end-to-end (data model, refresh mechanism, and a way to read it back, e.g. a simple query method or admin view) and let a follow-up task extend to additional trend types once the pattern is proven.

Note: this task has no hard dependency on task-32.3 (role-family taxonomy), but if that task is Done first, slicing the first trend by role family is preferred over an ungrouped total, since it's more actionable. If task-32.3 is not yet Done when this is picked up, ship the trend sliced by existing `ai_category` (from JobBoards::Categorizer) instead and note that role-family slicing is a natural follow-up.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A materialized view or rollup table stores at least one time-bucketed trend (recommended: weekly job-posting volume, sliced by role-family if task-32.3 is Done, otherwise by ai_category)
- [ ] #2 A documented, scheduled refresh mechanism keeps the rollup current (e.g. a recurring SolidQueue job matching existing scheduler patterns in config/queue.yml/config/recurring.yml)
- [ ] #3 A query method or admin-viewable path exists to read the trend data back out
- [ ] #4 RSpec coverage for the rollup's data correctness (given known postings across known weeks, the rollup produces the expected bucketed counts) and for the refresh job
- [ ] #5 Full RSpec suite passes
<!-- AC:END -->
