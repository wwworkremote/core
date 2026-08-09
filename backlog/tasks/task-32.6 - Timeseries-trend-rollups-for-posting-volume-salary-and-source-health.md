---
id: TASK-32.6
title: 'Timeseries trend rollups for posting volume, salary, and source health'
status: Done
assignee:
  - claude
created_date: '2026-08-08 15:50'
updated_date: '2026-08-08 22:08'
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
- [x] #1 A materialized view or rollup table stores at least one time-bucketed trend (recommended: weekly job-posting volume, sliced by role-family if task-32.3 is Done, otherwise by ai_category)
- [x] #2 A documented, scheduled refresh mechanism keeps the rollup current (e.g. a recurring SolidQueue job matching existing scheduler patterns in config/queue.yml/config/recurring.yml)
- [x] #3 A query method or admin-viewable path exists to read the trend data back out
- [x] #4 RSpec coverage for the rollup's data correctness (given known postings across known weeks, the rollup produces the expected bucketed counts) and for the refresh job
- [x] #5 Full RSpec suite passes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
task-32.3 (role-family taxonomy) is Done, so slicing by role_family per the task's own preference over ai_category.

Design decision: rollup table, not a Postgres `MATERIALIZED VIEW`. Reasoning: `RoleFamily.for(title)` is a Ruby-level ILIKE-alias lookup, not something a materialized view's SQL definition can call directly -- reproducing it as a raw-SQL CASE/ILIKE chain inside view DDL would duplicate RoleFamily's logic in two places and go stale silently if RoleFamily's aliases change without a matching migration. AC #1 explicitly allows "materialized view OR rollup table" -- a plain ActiveRecord-backed table populated by a scheduled job avoids the duplication, stays testable with ordinary specs, and needs no raw SQL.

Schema: `job_posting_trends` (week_start:date, role_family:string not-null with an "uncategorized" sentinel value for no-match rather than NULL -- Postgres unique indexes treat NULL as distinct per row, which would break upsert uniqueness for the no-match bucket; postings_count:integer). Unique index on [week_start, role_family] backs `upsert_all`.

Rollup logic: `JobPostingTrendRollup.call` -- full rebuild each run (pluck title+created_at for all postings with a created_at, tally by [week, family] in Ruby, `upsert_all` the result), not an incremental delta. Simpler and correctness-safe for this data volume (thousands of rows); avoids incremental-update edge cases (retroactive title edits, backfilled postings) that a delta-based approach would need to handle specially.

Job: `JobPostingTrendRollupJob` (queue_as :low, mediumweight! -- matches `JobLifecycle::ExpirySweepJob`, the closest existing precedent for a full-table maintenance sweep), thin wrapper calling the service, following the `SyncDashboardJob -> JobBoards::Syncer` split (logic in a plain service, job just schedules/calls it) so rollup correctness is testable without ActiveJob machinery.

Schedule: added to `config/recurring.yml` under both `development:` and `production:` (matches this file's existing duplicated-section pattern, no shared anchors used elsewhere in it) as `job_posting_trend_rollup: { class: JobPostingTrendRollupJob, schedule: every day at 5am }` -- daily, not weekly, so the current week's bucket stays live throughout the week rather than only updating once it's already over.

Query method: `JobPostingTrend.weekly_breakdown(week_start)` -> `{ "family_or_uncategorized" => count }` Hash, satisfies AC #3's "query method" option (no admin view built -- out of scope per the task's own "let a follow-up task extend" guidance).

Tests: `spec/services/job_posting_trend_rollup_spec.rb` (data correctness -- known postings across two different weeks and two different families produce the expected bucketed counts, re-running is idempotent/updates rather than duplicates) and `spec/jobs/job_posting_trend_rollup_job_spec.rb` (job delegates to the service). Migrate dev+test DBs, run full suite.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Investigated 2 system-spec failures (spec/system/user_pipeline_flow_spec.rb, spec/system/job_ingestion_flow_spec.rb) that appeared in one full-suite run. Reproduced with the exact same RSpec seed on the code WITHOUT this task's changes (git stash) -- passed. Reproduced again with the same seed WITH this task's changes restored -- also passed. Confirmed these are pre-existing Capybara/system-spec timing flakiness (browser-driver races), not a regression from this task -- same seed, same code, different outcome across runs is the signature of real nondeterminism, not a logic bug. Final full-suite run (root + packages/ingestion): 620 examples, 0 failures, clean.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added a weekly job-posting-volume trend rollup, sliced by RoleFamily (task-32.3).

**Changed:**
- db/migrate/20260808174429_create_job_posting_trends.rb (new table: week_start:date, role_family:string not-null with an "uncategorized" sentinel for no-match, postings_count:integer; unique index on [week_start, role_family]).
- app/models/job_posting_trend.rb (new) -- thin AR model plus `.weekly_breakdown(week_start)` query method (AC #3).
- app/services/job_posting_trend_rollup.rb (new) -- `JobPostingTrendRollup.call` does a full rebuild each run (pluck title+created_at, tally by [week, RoleFamily.for(title) || "uncategorized"] in Ruby, `upsert_all`) rather than an incremental delta -- simpler and avoids edge cases around retroactive title edits/backfills at this data volume.
- app/jobs/job_posting_trend_rollup_job.rb (new) -- thin job wrapper (queue_as :low, mediumweight!, matching JobLifecycle::ExpirySweepJob's precedent for full-table maintenance sweeps).
- config/recurring.yml -- added `job_posting_trend_rollup` to both development and production sections, daily at 5am (not weekly, so the current week's bucket stays live throughout the week).

**Design decision:** rollup table, not a Postgres `MATERIALIZED VIEW` -- `RoleFamily.for(title)` is Ruby-level ILIKE-alias matching that a materialized view's SQL definition can't call directly; reproducing that logic as raw SQL would duplicate it in two places and go stale silently. AC #1 explicitly allowed either option.

**Verified:**
- New specs: bucketing correctness across 2 weeks x 2 families + an uncategorized posting; re-run updates existing rows rather than duplicating (proves the upsert_all unique_by is working, not just that counts are right); job delegates to the service. 3 examples, 0 failures.
- Confirmed the recurring-task config is actually valid via `SolidQueue::RecurringTask.from_configuration` (not just YAML-parseable) -- would have caught an unresolvable class or bad schedule string before it could fail at boot in a real environment.
- Investigated and cleared 2 system-spec failures that appeared in one full run as pre-existing flakiness unrelated to this change (see implementation notes for the reproduction).
- Full RSpec suite (root + packages/ingestion): 620 examples, 0 failures, clean run.

**Not done, explicitly out of scope per the task:** salary drift and source-health trends (follow-up tasks per the task's own "ship one real trend" guidance); no admin view was built, only the query method.

This closes out all 6 subtasks under task-32 (Postgres capability upgrades, Aug 2026 audit). draft-1 (graph-query spike) remains intentionally deferred/unscheduled.
<!-- SECTION:FINAL_SUMMARY:END -->
