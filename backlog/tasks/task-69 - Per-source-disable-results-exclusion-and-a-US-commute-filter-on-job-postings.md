---
id: TASK-69
title: >-
  Per-source disable + results-exclusion, and a US/commute filter on job
  postings
status: To Do
assignee: []
created_date: '2026-08-19 01:58'
labels: []
dependencies: []
references:
  - app/models/job_boards/source.rb
  - app/models/company.rb
  - app/services/geo/commute_zone.rb
  - app/controllers/data_fetchers_controller.rb
  - app/controllers/admin/sources_controller.rb
  - app/controllers/admin/job_postings_controller.rb
  - app/views/job_postings/show.html.erb
priority: high
type: feature
ordinal: 78000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Trigger case: ArbeitNow (JobBoards::Source, `/admin/sources/17`) is exclusively non-US jobs. Two distinct needs that must not be conflated:

1. **Ingestion disable** — stop pulling new postings from a source. `/data_fetchers` currently only offers Run/Force per source (`app/views/data_fetchers/index.html.erb:44,54`); needs a Disable action too.
2. **Results exclusion** — the opposite lifecycle: KEEP ingesting a source (for future knowledge-building/analysis) but hide its postings from every job-posting-facing view (index, company page, source page) going forward. This must not require disabling ingestion, and must not require destroying/purging already-ingested postings the way `Company#disable_ingestion!` does.

Plus: a source/company-page-level bulk filter ("exclude everything from this source/company"), and a best-effort US-only + commute-accessible filter across job posting results, using existing infra rather than rebuilding it.

## What already exists (don't rebuild)
- `Company#ingestion_enabled` + `Company#disable_ingestion!` (hard, purges postings) / `Company#mark_not_interested!` (soft, only untouched postings) — `app/models/company.rb:10,78-93`. Pattern to mirror for Source, but note neither Company verb matches "keep ingesting, hide future postings too" — that's a new semantic.
- `JobBoards::Source` (`packages/ingestion/app/models/job_boards/source.rb`) has a dead `aasm_state` column (schema.rb:357-368) — present but no AASM block defined, unused by `DataAcquisitionManager`. Candidate to repurpose for the ingestion-pause state.
- `Geo::CommuteZone` (`app/services/geo/commute_zone.rb`) — full distance-based commute filter already built and wired via `JobPosting::Geocoding#enforce_commute_zone`, auto-`ignore!`s postings outside the zone. Home address is `ENV["HOME_LOCATION"]` (global, not per-user — `User` has no location column at all).
- `JobPosting.country_code` column exists but the research pass found no query-time scope filtering on it yet.
- Admin single-record job-posting hard delete already exists end-to-end (`Admin::JobPostingsController#destroy`, routed) but has **no button anywhere in any view** — only reachable via the bulk "Delete Permanently" trash action. Wire a real delete button into `job_postings/show` (public+admin were merged in TASK-66.1) — this is what closes "job_postings/5052 has no way to delete."
- `/admin/pipeline_prompts` already exists, fully built (`Admin::PipelinePromptsController`, `PipelinePrompt` model, `KNOWN_KEYS` for the 6 integration points) — the user's ask here may just be "I didn't know this existed" / needs a nav link (see TASK-65, already tracks the missing admin nav entry generally).

## Open product question (don't guess — ask before building)
Does "US-only" also exclude non-US *remote* postings, or only non-US *physical/non-remote* postings? `Geo::CommuteZone` today only judges non-remote postings by distance; country-code filtering is a separate axis that needs an explicit decision.

## Bug noticed in passing
`app/views/admin/sources/show.html.erb:33` renders `@source.payload`, which doesn't exist on `JobBoards::Source` (that attribute belongs to the unrelated `Source` model) — always renders `{}`. Fix while touching this view for the disable toggle.
<!-- SECTION:DESCRIPTION:END -->
