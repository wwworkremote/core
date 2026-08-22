---
id: TASK-81
title: >-
  Surface a stalled application funnel — ingestion outruns applications by
  ~1500:1
status: To Do
assignee: []
created_date: '2026-08-22 15:22'
labels: []
dependencies: []
priority: high
type: feature
ordinal: 94000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Measured 2026-08-22:

| | |
|---|---|
| Postings ingested | 6,136 (1,553 in the trailing 7 days) |
| Tracked (`UserJobPosting`) | 154 |
| Untriaged (`status: none`) | 143 |
| Favorited, never advanced | 9 |
| `PipelineStep` with `status: applied`, all time | 1, dated 2026-04-22 |

Undercounts somewhat — at least one application (posting 6068) was made without a full pipeline trail. But not by two orders of magnitude.

The scrapers are the healthiest subsystem and the application step is the bottleneck. Nothing in the app or in zdots surfaces this: there is no signal anywhere that says "143 untriaged, no application recorded in four months." The dashboard reports ingestion health, which is the number that is already fine.

## Shape
Not another scraper feature. Something that makes the funnel's narrowest point visible and uncomfortable — a staleness metric on the dashboard, or a periodic surfacing of the oldest untriaged favorites. Deliberately small: the failure mode here is building more platform instead of applying.

Related: `docs/agents/peer-contract-just3ws.md` records the same finding from the cross-system angle.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Days-since-last-application is visible without running a query
- [ ] #2 Untriaged count and oldest-untriaged age are surfaced
- [ ] #3 The signal is visible where Mike already looks, not on a new page he must remember to visit
- [ ] #4 No new scraping or ingestion capability is added by this task
<!-- AC:END -->
