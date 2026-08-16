---
id: TASK-54
title: Commute-zone auto-ignore runs after AnalysisJob may have already fired
status: To Do
assignee: []
created_date: '2026-08-16 15:21'
labels: []
dependencies: []
references:
  - app/models/concerns/job_posting/geocoding.rb
  - packages/ingestion/app/services/job_boards/syncer.rb
priority: low
type: enhancement
ordinal: 60000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Secondary finding from the TASK-52 investigation (fork aca3fd9eb676b5cc4), not the main ask -- filed to not lose it, not urgent. JobPosting::Geocoding#enforce_commute_zone (app/models/concerns/job_posting/geocoding.rb:32-36) auto-ignores postings blocked by Geo::CommuteZone, but this runs async via a background geocoding job, AFTER the posting is already saved -- unlike CompanyResolver and the new QualityFilter role check (both synchronous, before save). Syncer#enrich_if_needed's ignored? check happens at save time, so a commute-blocked posting can still get the full AnalysisJob (Categorizer + Embedder) treatment before geocoding determines it should have been ignored -- real but likely low-volume wasted processing, since it only affects non-remote postings whose location later resolves outside the commute zone.
<!-- SECTION:DESCRIPTION:END -->
