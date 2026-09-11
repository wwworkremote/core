---
id: TASK-73
title: >-
  JobBoards::AuditJob has never completed a successful run; not scheduled;
  shared-budget design flaw
status: Done
assignee: []
created_date: '2026-08-19 15:04'
updated_date: '2026-08-20 01:04'
labels: []
dependencies: []
references:
  - packages/ingestion/app/services/job_boards/auditor.rb
  - packages/ingestion/app/jobs/job_boards/audit_job.rb
  - config/recurring.yml
priority: medium
type: bug
ordinal: 86000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found by a pipeline-health audit pass, related to TASK-69's own finding that `audit_low_quality` (which TASK-69.2/69.3 now depend on for sweeping newly-excluded-source/non-US postings) couldn't get a turn due to backlog size.

Three compounding issues:
1. `JobBoards::AuditJob` is **not registered in `config/recurring.yml`** at all -- it only runs on manual/ad-hoc trigger (the "Run Audit" button on `/data_fetchers`).
2. Its only two invocations ever (Aug 11-12) both failed on a `NameError: uninitialized constant JobBoards::AuditJob::Auditor` -- already fixed by commit `d722f091` (fully-qualified `JobBoards::Auditor.new(...)` in `packages/ingestion/app/jobs/job_boards/audit_job.rb:8`), but means `audit_low_quality` has **never completed a single successful pass** in this app's history, independent of issue #3.
3. `JobBoards::Auditor::AUDITS` (`packages/ingestion/app/services/job_boards/auditor.rb:9-15`) shares one `@stats[:fixed] < @limit` budget across all 5 audit types (`audit_missing_postings`, `audit_missing_category`, `audit_missing_embedding`, `audit_missing_geocoding`, `audit_low_quality`), run in that fixed order -- with `missing_postings` (~4,776) and `missing_category` (~4,711) backlogs currently far exceeding the default `limit: 100`, `audit_low_quality` never gets a turn.

Recommend: (a) schedule `AuditJob` in `config/recurring.yml` so it actually runs periodically, (b) give `audit_low_quality` its own budget or run it first/separately from the other 4, since it's the one enforcing exclusion/quality decisions (TASK-69's source-exclusion and country-filter sweeps depend on it), not just backfilling metadata.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Two fixes: (1) registered JobBoards::AuditJob in config/recurring.yml (daily, alongside the other full-table maintenance sweeps) -- it was previously manual-trigger only. (2) Gave audit_low_quality its own independent budget counter (@stats[:low_quality_fixed]) instead of sharing @stats[:fixed] with the other four audits -- missing_postings (~4,776 backlog) and missing_category (~4,711 backlog) were exhausting the shared limit every run before audit_low_quality (which TASK-69's exclusion/country-filter sweeps depend on) ever got a turn. Implemented via a worktree-isolated agent, reviewed the diff directly before merging, added 2 new specs (auditor_spec.rb, 10/10 passing), RuboCop clean. Committed as 91516ca8 on main (cherry-picked from the worktree commit 4fb028b6, which passed the pre-commit hook cleanly with no bypass needed once a stale worktree's missing tailwind.css build asset -- unrelated to this change -- was rebuilt).
<!-- SECTION:FINAL_SUMMARY:END -->
