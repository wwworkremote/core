---
id: TASK-85
title: >-
  Enforce the US-only rule in code — country_code exists but nothing filters on
  it
status: To Do
assignee: []
created_date: '2026-08-24 19:02'
labels: []
dependencies: []
priority: high
type: bug
ordinal: 98000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Mike keeps seeing non-US postings (e.g. #5852, `IT Support Disponent (m/w/d)` at `IT Fabrik Systemhaus GmbH & Co.KG`, Bitburg). The US-only rule is a standing constraint but **exists nowhere in the codebase.**

`grep` for country/US filtering across `app/services/ingestion`, `app/services/job_boards`, and `app/models/job_posting.rb` returns only the schema annotation. There is no filter at ingestion, at ranking, or in any index scope.

## The data is half-there, which is why this is fixable

`job_postings.country_code` **exists and is indexed**. Current distribution:

| country_code | count |
|---|---|
| nil | 4150 |
| US | 690 |
| DE | 533 |
| GB | 298 |
| IE | 48 |
| CA | 48 |
| AU | 38 |
| IN | 38 |

So roughly **1,000 postings are positively known non-US and still in the corpus**, and 4,150 have no country at all. 547 postings carry `GmbH` in the company name.

## Two separable problems — do not conflate them

1. **Known non-US are not filtered.** Cheap and immediate: the ~1,000 rows with a non-US `country_code` should not surface in browse, triage, or matching.
2. **`country_code` is unpopulated for 71% of the corpus.** A filter on `country_code` alone silently keeps every unknown row. Backfill needs a derivation pass — `location` text, source origin (Arbeitnow and Jobicy are EU/global-first), and company-name markers are all signals.

**Default for unknown matters and is a judgment call.** Hiding all 4,150 nil rows would hide most of the corpus, including real US jobs. Suggest: filter known-non-US now, surface unknown with a visible "country unknown" marker, and backfill in the background — rather than a silent drop either way.

## Acceptance criteria

- Postings with a known non-US `country_code` do not appear in browse, triage, or matching
- The default for `country_code IS NULL` is an explicit documented decision, not an accident of the query
- A backfill derives `country_code` from location text and source origin for the 4150 nil rows
- Posting #5852 (Bitburg, GmbH) no longer surfaces
- The rule lives in one place that ingestion, triage, and matching all route through, not three separate WHERE clauses
- Counts before/after are recorded so the filter's blast radius is known rather than assumed

## Related defect found while investigating

There are **two source tables**: `sources` (21 rows) and `job_boards_sources` (29 rows). `JobPosting belongs_to :source` resolves to `sources`. This is the same split that raises `AssociationTypeMismatch` when a script uses `JobBoards::Source`, and it explains why 741 postings group under a source_id that resolves to no name. Source-based geo filtering will be unreliable until that is reconciled.
<!-- SECTION:DESCRIPTION:END -->
