---
id: TASK-69.3
title: US-only / commute-accessible filter on job postings results
status: Done
assignee: []
created_date: '2026-08-19 01:58'
updated_date: '2026-08-19 11:59'
labels: []
dependencies: []
modified_files:
  - app/controllers/admin/pipeline_filters_controller.rb
  - app/views/admin/pipeline_filters/index.html.erb
  - spec/requests/admin/pipeline_filters_spec.rb
parent_task_id: TASK-69
priority: medium
type: feature
ordinal: 81000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Blocked on a product decision (see TASK-69's "Open product question"): does US-only exclude non-US *remote* postings too, or only non-US physical/non-remote postings? Ask before building.

**Major finding while building TASK-69.2**: the mechanism already exists and is already wired into the same auto-ignore path. `JobBoards::QualityFilter#country_mismatch?` (`packages/ingestion/app/services/job_boards/quality_filter.rb`) already compares `job_posting.country_code` against `User#preferred_countries` (array column) and returns non-useful (auto-ignored) on mismatch -- gated at both sync-time and via `JobBoards::Auditor#audit_low_quality`, exactly the pattern TASK-69.2 just extended for source-exclusion. It currently applies unconditionally to ANY posting with a `country_code` set, remote or not -- which is exactly the open product question above, now grounded in real code rather than hypothetical.

What's actually missing:
- `User.first.preferred_countries` needs to actually be populated (e.g. `["US"]`) -- unclear if it already is; check before assuming this filter is inert.
- No admin UI to view/edit `preferred_countries` today (was surfaced read-only nowhere per the original research pass).
- The remote-exemption product question above still needs an answer -- if remote-but-non-US postings should be kept, `country_mismatch?` needs a `return false if job_posting.remote?`-style guard before it does anything else.
- `Geo::CommuteZone` (commute-distance filtering) is the separate, already-complete axis for non-remote physical accessibility -- don't conflate the two, they're already cleanly split in the code.

"Down to what is possible" per the user — many postings won't have a clean `country_code`, so this is a best-effort filter regardless.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Decision (confirmed with the user): non-US postings are excluded even when tagged remote -- no remote-exemption guard needed.

Turned out to need zero new filtering logic: `JobBoards::QualityFilter#country_mismatch?` already did exactly this, comparing `job_posting.country_code` against `User#preferred_countries`, already wired into both the sync-time path and the Auditor sweep. It was just inert -- `User.first.preferred_countries` was `[]`.

- Set `User.first.preferred_countries = ["US"]` directly (real data change, not code).
- Added a "Country Filter" card to `/admin/pipeline_filters` for visibility (was previously surfaced nowhere), matching that page's existing pattern for DB/ENV-backed config values (commute radii).
- Swept existing non-US visible postings: found 7 candidates, the shared-budget `JobBoards::Auditor` couldn't reach them in one pass (its `@limit` was exhausted by a large `missing_postings`/`missing_category` backlog before `audit_low_quality` got a turn -- a pre-existing pipeline-backlog issue, not something this task caused or fixed). Ran the `audit_low_quality` check directly instead: ignored 13 low-quality/excluded postings, 3 non-US postings were correctly left alone because they're already favorited/archived (may_ignore? false) -- matches the established "never override a user's own decision" pattern from Company/Source exclusion.
- No settings-edit UI built for `preferred_countries` -- deliberately deferred, following this codebase's own precedent (`HOME_LOCATION` for Geo::CommuteZone is also a single operator-set value with no UI, ENV-only). Ask Mike directly (or via a console one-liner) if it ever needs to change.
- 2 new spec examples. Full suite passing (630 examples prior to this task's own additions; final count folded into TASK-69.4's verification run).
<!-- SECTION:FINAL_SUMMARY:END -->
