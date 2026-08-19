---
id: TASK-74
title: 8 CrawlDiscoveryJob sources haven't ingested anything new since ~April
status: To Do
assignee: []
created_date: '2026-08-19 15:04'
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
