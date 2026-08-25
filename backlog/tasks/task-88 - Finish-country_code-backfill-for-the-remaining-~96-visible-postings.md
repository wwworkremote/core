---
id: TASK-88
title: Finish country_code backfill for the remaining ~96 visible postings
status: To Do
assignee: []
created_date: '2026-08-25 13:13'
labels: []
dependencies:
  - TASK-87
priority: low
type: chore
ordinal: 101000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Follow-up to TASK-85. `bin/backfill_country_codes` derives `country_code` for browse-visible postings (not ignored/purged/expired) that predate `GeocodingJob` storing it. Of ~110 relevant rows, about a dozen resolved before the run tripped Nominatim's live rate limit (see TASK-87 -- the circuit breaker that should have paused the run instead did nothing, so it just kept failing until the script's own new rate-limit guard stopped it).

Re-run `bin/backfill_country_codes` once Nominatim's rate limit has cleared (unknown duration; give it real time before retrying -- do not hammer it to find out). `--status` shows current counts without making any calls.

## Acceptance criteria
- `bin/backfill_country_codes --status` shows 0 (or near-0, accounting for genuinely un-geocodable location text like bare "Remote") remaining backfillable rows
- No repeat of the rate-limit issue (either TASK-87 is fixed first so the circuit breaker actually works, or the run is spread out manually)
<!-- SECTION:DESCRIPTION:END -->
