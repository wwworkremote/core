---
id: TASK-79
title: >-
  Rebuild crawl URLs for 7 dead CrawlDiscoveryJob sources (builtin, remoteio,
  flexjobs, bestjobs, echojobs, roberthalf, remoteok)
status: To Do
assignee: []
created_date: '2026-08-20 01:15'
labels: []
dependencies: []
references:
  - app/models/board_query.rb
  - packages/ingestion/app/services/data_acquisition_manager/crawl_runner.rb
  - .claude/skills/pipeline-health/scripts/discovery_crawl_status.rb
priority: low
type: bug
ordinal: 92000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Follow-up from TASK-74 (which fixed the shared scheduling/NameError bug, but that only benefits `cord` -- the one source that was actually reaching the crawl step). These 7 never get that far:

**6 sources with no crawl URL at all** (`builtin`, `remoteio`, `flexjobs`, `bestjobs`, `echojobs`, `roberthalf`): `BoardQuery::BUILDERS` (`app/models/board_query.rb:19-25`) has no entry for any of these, and none have `query_params["start_url"]` set. `CrawlRunner#enqueue_crawl_query` (`packages/ingestion/app/services/data_acquisition_manager/crawl_runner.rb:20-26`) hits `return if url.blank?` -- the crawl job is never even enqueued. This is why `DiscoveryLink` has zero rows for any of them, ever.

**1 source with a dead URL scheme** (`remoteok`): `BoardQuery#build_remoteok_url` (`app/models/board_query.rb:103-106`) generates keyword-slug URLs like `https://remoteok.com/remote-staff-ruby-engineer-jobs` -- confirmed via curl that this now 302-redirects to the homepage. The site changed its URL scheme; the builder needs live-markup verification against whatever RemoteOK uses now.

Each of these needs individual live-DOM verification (the same discipline used for the extension's provider fixes in TASK-37: never guess a selector/URL scheme, check it against a real live page first) -- do not attempt to fix all 7 blind in one pass. `.claude/skills/pipeline-health/scripts/discovery_crawl_status.rb` classifies each source's current state (CRAWL-DEAD / BACKED UP / HEALTHY) and is a fast way to confirm each fix actually worked once applied.
<!-- SECTION:DESCRIPTION:END -->
