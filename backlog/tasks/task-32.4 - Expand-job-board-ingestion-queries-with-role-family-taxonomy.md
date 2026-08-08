---
id: TASK-32.4
title: Expand job-board ingestion queries with role-family taxonomy
status: Done
assignee:
  - claude
created_date: '2026-08-08 15:50'
updated_date: '2026-08-08 17:11'
labels: []
milestone: m-0
dependencies:
  - TASK-32.3
parent_task_id: TASK-32
priority: medium
type: feature
ordinal: 35000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Goal: use the role-family taxonomy from task-32.3 to broaden what gets fetched at ingestion time, so adjacent/lateral title wordings (e.g. searching a "staff-plus IC" family fetches postings titled "Staff Engineer", "Staff Software Engineer", and "Principal Engineer", not just one literal string) actually reach the database instead of being invisible to every downstream matching/search feature.

Depends on task-32.3 (role-family taxonomy map): this task consumes that task's lookup/alias data. Do not start until task-32.3 is Done -- its output (the family->aliases structure and lookup API) is the input this task builds on.

Two call sites currently send one literal keyword string per query:
- `BoardQuery#terms` (app/models/board_query.rb) -- `terms.first` is used directly as the keyword param in build_cord_url/build_linkedin_url/build_indeed_url/build_dice_url/build_remoteok_url.
- `DataAcquisitionManager::CrawlDefaults::URLS` (packages/ingestion/app/services/data_acquisition_manager/crawl_defaults.rb) -- hardcoded single-keyword fallback URLs per board.

Scope: expanding query generation to cover a role family's alias list (e.g. by generating multiple BoardQuery rows or multiple crawl URLs per family instead of one), not rewriting the board URL builders themselves. Rate-limiting/circuit-breaker behavior (ApiGuard, already governing these fetchers) must continue to apply per-board regardless of how many queries a family expands into -- do not bypass or weaken existing cooldown/circuit-breaker protections by generating a burst of new queries.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Given a role family from task-32.3's taxonomy, ingestion generates board queries/crawl targets covering that family's alias titles, not just one literal string
- [x] #2 Existing single-term BoardQuery rows and CrawlDefaults behavior continue to work unchanged for boards/queries not using a role family
- [x] #3 ApiGuard rate-limiting/circuit-breaker behavior is verified unaffected -- expanding one family into N alias queries does not bypass per-board cooldown or trip the circuit breaker faster than before
- [x] #4 RSpec coverage demonstrates a role family expanding into multiple queries/URLs across at least two of the board builders (e.g. indeed and dice)
- [x] #5 Full RSpec suite passes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Correction to this task's own description before implementing (verify-before-trust, same discipline as task-32.2): traced the actual crawl path (`DataAcquisitionManager.dispatch` -> `CrawlRunner.call` -> `Scraper::CrawlDiscoveryJob`) and confirmed `ApiGuard` does NOT govern this path at all. `ApiGuard`'s `with_api_guard`/`source_locked?` calls only appear in `ServiceRunner`-dispatched API-fetcher classes (Adzuna, Lever, etc.) and in specific jobs (GeocodingJob, LinkMonitorJob) -- `Scraper::CrawlDiscoveryJob` only checks `SystemSetting.paused?` and relies on `ApplicationJob`'s `idempotent!` concurrency control, keyed on `"crawl/#{board}/#{url}"` (board+URL, not board alone), as its only per-request protection. This task's AC #3 assumed ApiGuard applies here; it doesn't. Reinterpreting AC #3 accordingly: what must NOT break is the existing idempotency-key uniqueness (N aliases must produce N distinct URLs/keys, not accidental duplicates that would self-suppress under `idempotent!`), not an ApiGuard cooldown that was never in this path to begin with.

Also confirmed: `CrawlRunner.enqueue_crawls` already enqueues one crawl job per `BoardQuery` row for a given board_name (`BoardQuery.where(board_name: slug.downcase)`, then `.each`). So the mechanism for "one role family -> many crawls" already exists at the CrawlRunner layer with zero changes needed there -- the only gap is that nothing generates multiple `BoardQuery` rows from a role family today. `CrawlDefaults::URLS` is explicitly documented as a fallback "used when a board has no BoardQuery rows of its own yet" -- once real BoardQuery rows exist for a board, CrawlRunner prefers them, so CrawlDefaults doesn't need touching either.

Implementation: `BoardQuery.create_for_role_family!(family, board_name:, **attrs)` class method -- iterates `RoleFamily.aliases_for(family)`, creates one `BoardQuery` row per alias with `terms: [alias]`, forwarding any other attrs (remote:, priority:, query_params:) to every created row. No BoardQuery validations exist today (confirmed by grep), so no new validation concerns.

Tests added to `spec/models/board_query_spec.rb`: a role family expands into N BoardQuery rows (N = alias count) for a board; each row produces a distinct URL for at least two builders (indeed, dice) -- proving no accidental URL/idempotency-key collisions; an unrelated existing single-term BoardQuery is unaffected (AC #2).

CrawlDefaults, CrawlRunner, and Scraper::CrawlDiscoveryJob are not modified -- zero diff, confirmed via git diff before finalizing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
AC #3 evidence, reinterpreted per the investigation recorded in the plan: ApiGuard doesn't govern this path at all (verified), so 'unaffected' means the idempotency-key uniqueness that DOES protect this path stays intact -- proven by the 'produces distinct URLs across builders' spec (indeed_queries.map(&:build_url).uniq.size == indeed_queries.size, same for dice). Also confirmed via git diff that CrawlDefaults, CrawlRunner, and Scraper::CrawlDiscoveryJob have zero changes -- nothing about the existing crawl-dispatch path was touched.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added `BoardQuery.create_for_role_family!(family, board_name:, **attrs)`, which creates one `BoardQuery` row per alias in a `RoleFamily` (task-32.3). `CrawlRunner` already enqueues one crawl job per `BoardQuery` row for a board -- so this required zero changes to the crawl-dispatch path itself; only a generator for the rows needed to exist.

**Changed:** app/models/board_query.rb (+method), spec/models/board_query_spec.rb (+3 examples).

**Correction from this task's own description:** investigated before implementing and found `ApiGuard` does not govern the crawl path (`CrawlRunner`/`Scraper::CrawlDiscoveryJob`) at all -- it only governs `ServiceRunner`-dispatched API fetchers and specific jobs (GeocodingJob, LinkMonitorJob). The crawl path's only per-request protection is `ApplicationJob`'s `idempotent!` concurrency control keyed on board+URL. Recorded this correction in the plan and re-scoped AC #3's verification accordingly (proving alias-derived URLs are distinct, not proving an ApiGuard cooldown that isn't in this path).

**Verified:**
- New specs: N aliases -> N BoardQuery rows with correct terms; distinct URLs (no idempotency-key collisions) across indeed and dice; an unrelated existing single-term BoardQuery is unaffected.
- `git diff --stat` confirms zero changes to CrawlDefaults, CrawlRunner, or Scraper::CrawlDiscoveryJob.
- Full RSpec suite (root + packages/ingestion): 613 examples, 0 failures.

**Not done:** CrawlDefaults itself was not touched -- it's documented as a fallback for boards with no BoardQuery rows yet, and once role-family-generated rows exist for a board, CrawlRunner prefers them automatically, so it doesn't need to be.
<!-- SECTION:FINAL_SUMMARY:END -->
