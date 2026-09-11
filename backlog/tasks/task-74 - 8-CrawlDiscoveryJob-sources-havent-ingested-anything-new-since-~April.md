---
id: TASK-74
title: 8 CrawlDiscoveryJob sources haven't ingested anything new since ~April
status: Done
assignee: []
created_date: '2026-08-19 15:04'
updated_date: '2026-08-20 01:15'
labels: []
dependencies: []
references:
  - packages/ingestion/app/jobs/scraper/crawl_discovery_job.rb
priority: low
type: spike
ordinal: 87000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found by a pipeline-health audit pass. Sources `bestjobs`, `builtin`, `cord`, `echojobs`, `flexjobs`, `remoteio`, `remoteok`, `roberthalf` (all registered to `Scraper::CrawlDiscoveryJob`) show `last_synced_at` refreshing normally every ~6h (fetch attempts are happening, no `FailedExecution` rows) but `last_ingested_at` frozen at 2026-04-24 -- roughly 4 months with zero new postings despite "successful" runs. Either these boards genuinely have nothing new (unlikely across 8 sources simultaneously), or `Scraper::CrawlDiscoveryJob`/its extraction rules are silently no-oping (stale selectors, site layout changed) without raising an error. Needs investigation: check what `CrawlDiscoveryJob` is actually finding vs. discarding for one of these sources before assuming the rest share the same cause.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
CORRECTED (2026-08-20): the "6 of 8 should self-heal" claim below was wrong -- superseded by a follow-up pass from the same investigating agent, made after this summary was first written but before its worktree was cleaned up (a few of its findings arrived after I'd already merged its first-pass diff, so this record is being updated after the fact).

Real breakdown, verified against the dev DB: only **cord** has ever had a single `DiscoveryLink` row. The original two fixes (scheduling + NameError) are correct and needed, but only cord benefits from them directly.

- **cord** -- fixed and confirmed end-to-end (live drain test: 3 pending links → processed, JobPosting count 78 → 81, no errors).
- **remoteok** -- has a URL builder (`BoardQuery#build_remoteok_url`) but it's dead: the generated keyword-slug URL now 302-redirects to RemoteOK's homepage (site changed its URL scheme). Separate per-source fix, needs live-markup verification.
- **builtin, remoteio, flexjobs, bestjobs, echojobs, roberthalf** (6 of 8) -- `BoardQuery::BUILDERS` (`app/models/board_query.rb:19-25`) has no entry for any of these, and none have `query_params["start_url"]` set, so `CrawlRunner#enqueue_crawl_query` (`packages/ingestion/app/services/data_acquisition_manager/crawl_runner.rb:20-26`) hits `return if url.blank?` -- **the crawl job is never even enqueued** for these 6. This is real per-board work (one URL builder/scheme each), not something this fix touches. Matches the ticket's own stop condition ("if every one needs individual rework, stop and document") -- filing as follow-up work, not attempting blind here.

Also closed a related gap found during review: neither fix touched `JobBoards::Source#last_ingested_at` (the exact metric this ticket was about) -- Enricher's create-posting paths only marked the DiscoveryLink "processed", not the Source. Fixed in a same-day follow-up commit (a346e5ab) wiring it in, matching the existing ServiceRunner/Syncer convention.

Diagnostic tool for next time: `.claude/skills/pipeline-health/scripts/discovery_crawl_status.rb` (read-only, run via `bin/rails runner`) classifies every crawl-based source as CRAWL-DEAD / BACKED UP / HEALTHY -- use it to re-check cord's status and to triage the 6-source BUILDERS gap when that follow-up work starts.

Commits: f51f875a (scheduling + NameError fix), a346e5ab (last_ingested_at wiring).
<!-- SECTION:FINAL_SUMMARY:END -->
