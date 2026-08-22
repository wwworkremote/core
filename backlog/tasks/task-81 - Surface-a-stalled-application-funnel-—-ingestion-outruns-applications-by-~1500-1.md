---
id: TASK-81
title: Surface a stalled application funnel — and fix the numbers it reports
status: To Do
assignee: []
created_date: '2026-08-22 15:22'
updated_date: '2026-08-22 15:39'
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

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-08-22 — **correcting this task's own premise.** It was filed reading only `UserJobPosting.status`, which gave "2 applied, 1 pipeline event dated 2026-04-22, 143 untriaged." That is one of two disagreeing sources. Reading `JobPosting.status` instead: **4 applied** (Edfinity, BNSF Railway, Omada Health, Follett), 452 ignored, 469 purged, 4,739 expired, 407 none. Substantially more triage has happened than this task claimed.

The funnel is narrow but not as dead as filed. The application step is still the bottleneck — 4 applications against 6,136 ingested — but "no application in four months" was wrong.

**Blocked on TASK-82.** Any staleness metric built now would inherit the same ambiguity, since which model you query changes the answer. Fix the dual state machine first, then build the signal on the reconciled number.
<!-- SECTION:NOTES:END -->
