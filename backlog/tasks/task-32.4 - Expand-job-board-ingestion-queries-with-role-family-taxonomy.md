---
id: TASK-32.4
title: Expand job-board ingestion queries with role-family taxonomy
status: To Do
assignee: []
created_date: '2026-08-08 15:50'
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
- [ ] #1 Given a role family from task-32.3's taxonomy, ingestion generates board queries/crawl targets covering that family's alias titles, not just one literal string
- [ ] #2 Existing single-term BoardQuery rows and CrawlDefaults behavior continue to work unchanged for boards/queries not using a role family
- [ ] #3 ApiGuard rate-limiting/circuit-breaker behavior is verified unaffected -- expanding one family into N alias queries does not bypass per-board cooldown or trip the circuit breaker faster than before
- [ ] #4 RSpec coverage demonstrates a role family expanding into multiple queries/URLs across at least two of the board builders (e.g. indeed and dice)
- [ ] #5 Full RSpec suite passes
<!-- AC:END -->
