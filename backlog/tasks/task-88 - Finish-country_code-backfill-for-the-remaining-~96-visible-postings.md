---
id: TASK-88
title: Finish country_code backfill for the remaining ~96 visible postings
status: In Progress
assignee: []
created_date: '2026-08-25 13:13'
updated_date: '2026-08-25 15:39'
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

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-08-25: re-ran bin/backfill_country_codes. Resolved 11 more rows (96 -> 85 remaining). Hit Nominatim's rate limit again after only 37 requests despite the 1 req/sec throttle -- the script's guard correctly stopped immediately this time (no silent hammering), but the limit's re-triggering that fast suggests some lingering penalty from the earlier abuse, not a clean per-second window. Don't retry in a tight loop; space future attempts out over real time, and TASK-87 (the actually-broken circuit breaker) would make this self-managing instead of needing manual spacing.
<!-- SECTION:NOTES:END -->
