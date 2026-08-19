---
id: TASK-69.3
title: US-only / commute-accessible filter on job postings results
status: To Do
assignee: []
created_date: '2026-08-19 01:58'
labels: []
dependencies: []
parent_task_id: TASK-69
priority: medium
type: feature
ordinal: 81000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Blocked on a product decision (see TASK-69's "Open product question"): does US-only exclude non-US *remote* postings too, or only non-US physical/non-remote postings? Ask before building.

Existing infra to reuse, not rebuild: `Geo::CommuteZone` (`app/services/geo/commute_zone.rb`) already auto-`ignore!`s non-remote postings outside the commute zone via `JobPosting::Geocoding#enforce_commute_zone`. `JobPosting.country_code` exists but has no query-time scope yet. "Down to what is possible" per the user — many postings won't have a clean `country_code`, so this is a best-effort filter, not a hard guarantee.
<!-- SECTION:DESCRIPTION:END -->
