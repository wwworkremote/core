---
id: TASK-32
title: 'Postgres capability upgrades: hybrid search, title taxonomy, schema cleanup'
status: Done
assignee: []
created_date: '2026-08-08 15:46'
updated_date: '2026-08-08 22:08'
labels: []
milestone: m-0
dependencies: []
priority: high
type: feature
ordinal: 31000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Parent tracking task for a set of follow-ups from the 2026-08-08 data-capability audit of this repo's Postgres usage (pgvector/HNSW, pg_search, pg_trgm, ltree, no timeseries extension).

Two gaps were identified in how job search/matching works today:
1. JobPosting has two disconnected search paths -- `JobPosting#search` (pg_search keyword+trigram) and `JobPosting.semantic_search` (pgvector cosine via VectorIntelligence) -- callers must pick one; results are never combined/fused. This caps match quality for every search and matching feature in the app (JobSearchManager, admin search, any future search UI), since keyword search misses paraphrases and vector search blurs past exact terms/acronyms.
2. Title/seniority matching (e.g. "Staff Engineer" vs "Principal Engineer" vs "Engineering Manager" vs "Director of Engineering") has exactly one hand-rolled precedent in the codebase -- `JobPosting::MANAGEMENT_TIER_TITLE_PATTERN` (app/models/job_posting.rb) -- used only as a binary management-tier UI toggle. Job-board ingestion (BoardQuery#terms, DataAcquisitionManager::CrawlDefaults) sends one literal keyword string per board query, so adjacent/lateral titles are never even fetched -- no amount of downstream matching can surface postings that were never ingested.

Two smaller items were flagged as schema hygiene / roadmap gaps:
3. The `ltree` Postgres extension has been enabled since 2020 (db/migrate/20220728223111_enable_extensions.rb... actually enabled in an early extensions migration) and is never referenced by any model or service. There is a real hierarchy in the schema today it could serve (`domains.root_domain_id`, a self-referential parent/child FK, just indexed in the 20260804232042 migration) -- but that hierarchy currently works fine as a plain adjacency list at present scale.
4. No timeseries/trend capability exists (no TimescaleDB, no rollup/materialized views) despite the domain being rich in time-series-shaped data (posting volume, salary drift, source ingestion health over time). `SystemInsight` (app/models/system_insight.rb) looks like it was built toward this but nothing populates trend data yet.

A graph-capability question (property-graph / SQL-PGQ support in a future Postgres version) was also raised but is explicitly OUT of scope for execution here -- see the deferred spike subtask.

Subtasks are sequenced from most commonly valuable shared functionality (benefits every search/match path with zero new dependencies) down to the most specific/narrow enhancement, per the DAG recorded in this task's plan once execution starts.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 All non-deferred subtasks under this parent are Done with their own acceptance criteria independently verified
- [x] #2 No regression in existing JobPosting search/match behavior (existing specs for JobPosting#search, VectorIntelligence, JobSearchManager::MatcherService, GeocodingJob/board_query flows still pass)
- [x] #3 Full RSpec suite (root spec/ and packages/ingestion/spec/) green after each subtask lands
- [x] #4 Schema/extension decisions (ltree) are either adopted with a real caller or the extension is removed -- not left in the ambiguous unused-but-enabled state found in the audit
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
All 6 subtasks Done, executed sequentially from most commonly shared functionality down to the narrowest new capability, per the DAG:

1. **task-32.1** -- Hybrid search fusion (keyword + vector) for JobPosting via Reciprocal Rank Fusion. Zero dependencies, benefits every search/match path.
2. **task-32.2** -- Removed the unused `ltree` extension after investigation showed zero callers (and that the one hierarchy it could have served, `domains.root_domain_id`, is itself unused).
3. **task-32.3** -- `RoleFamily` title-taxonomy lookup module, 5 families, aliases reviewed against real sampled JobPosting titles.
4. **task-32.4** -- `BoardQuery.create_for_role_family!`, generating ingestion queries from a role family (discovered ApiGuard doesn't govern this path; corrected the task's own premise before implementing).
5. **task-32.5** -- Generalized the binary management-tier filter into 5-family role filtering in the JobPostings UI; deleted the now-fully-dead old mechanism rather than leaving it orphaned.
6. **task-32.6** -- Weekly job-posting-volume trend rollup sliced by role family, with a scheduled daily refresh job.

Three real corrections to this parent task's and its subtasks' own initial assumptions surfaced and were documented in-place during execution (ltree/root_domain_id not backing the company blocklist; ApiGuard not governing the crawl path; a stray flaky-test scare traced to pre-existing Capybara nondeterminism, not a regression) -- verify-before-trust held throughout, including against my own prior writing.

draft-1 (graph-query capability spike) remains intentionally Draft/unscheduled -- no concrete driving use case exists yet, per its own text.

All changes are committed to main in small, reviewable, task-scoped commits (one feature commit + one backlog-tracking commit per subtask). Full RSpec suite (root + packages/ingestion) was green after every subtask.
<!-- SECTION:FINAL_SUMMARY:END -->
