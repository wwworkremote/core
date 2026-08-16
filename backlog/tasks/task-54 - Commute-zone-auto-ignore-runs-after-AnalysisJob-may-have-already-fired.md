---
id: TASK-54
title: Commute-zone auto-ignore runs after AnalysisJob may have already fired
status: Done
assignee: []
created_date: '2026-08-16 15:21'
updated_date: '2026-08-16 16:11'
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

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Considered the full fix (defer AnalysisJob's enqueue until after geocoding resolves, matching TASK-52's synchronous-guard pattern) but rejected it: GeocodingJob silently no-ops when Geocoder.search returns nothing (bad/unrecognized address) or errors out (rate limits, network errors) -- job_posting.update! is only called inside `if result`, so a posting whose geocoding permanently fails would never trigger enforce_commute_zone, and AnalysisJob would never get enqueued at all. That's a strictly worse outcome (a posting stuck uncategorized forever) than the processing waste this task describes, for a fix explicitly filed as low-priority/low-volume.

Shipped the safe alternative instead: JobBoards::AnalysisJob re-checks job_posting.ignored? at the START of #perform, not just at enqueue time. GeocodingJob (:light queue, fast HTTP call) and AnalysisJob (:heavy queue, slow LLM call) get enqueued around the same moment but don't execute at the same time -- this catches the common case where the faster queue resolves (and auto-ignores via enforce_commute_zone) before the slower one actually runs, with zero risk of a stuck posting since it's purely additive, not a change to enqueue timing.

New packages/ingestion/spec/jobs/job_boards/analysis_job_spec.rb (3 examples, had zero prior coverage) covers the normal path, a missing job_posting_id, and the new ignored-by-execution-time guard.

Verified: full combined suite (spec + packages/ingestion/spec) -- 729 examples, 0 failures, 91.28% coverage. RuboCop clean.
<!-- SECTION:FINAL_SUMMARY:END -->
