---
id: TASK-40
title: Normalize employment_type at ingestion + expose contract-role filter
status: In Progress
assignee: []
created_date: '2026-08-14 17:31'
updated_date: '2026-08-14 17:31'
labels:
  - ingestion
  - job_postings
dependencies: []
priority: high
type: feature
ordinal: 46000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Only 4 of 4,701 JobPostings have data["employment_type"] set, and those 4 are inconsistent ("FULL_TIME" vs "Full-time" vs garbage). Root cause: JobBoards::Syncer::AttributeMapper stores each provider's full raw JSON into job_posting.data but never normalizes employment-type signal that's already present under provider-specific keys (Lever categories.commitment, Remotive job_type, Jobicy jobType, Arbeitnow job_types, Adzuna contract_time/contract_type). Fix at the mapper (one normalization step keyed by provider slug, written into `data` before finalize_body's merge so it survives), backfill existing rows from data already on disk (no re-scrape needed), then add a `contract_only`-style scope + index UI filter checkbox next to the existing remote filter. Driven by Mike's need to diversify into contract work as an interim option while searching for a long-term role.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 AttributeMapper normalizes employment_type into data for adzuna/lever/arbeitnow/jobicy/remotive without breaking existing per-provider mapper specs
- [ ] #2 One-off backfill updates existing postings' data["employment_type"] from already-stored raw payload, no re-fetch
- [ ] #3 JobPosting has a scope for filtering to contract-type postings
- [ ] #4 job_postings#index exposes a contract filter checkbox mirroring the existing remote checkbox, with request spec coverage
<!-- AC:END -->
