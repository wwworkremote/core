---
id: TASK-23
title: Apply concurrency limits to heavy job classes
status: Done
assignee: []
created_date: '2026-07-27 21:57'
updated_date: '2026-07-28 00:21'
labels: []
dependencies: []
priority: medium
ordinal: 22000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
ApplicationJob already provides heavyweight!/mediumweight!/lightweight!/idempotent! (Solid Queue's limits_concurrency). Only LLM::BatchMatchJob actually uses it. JobBoards::GeocodingJob, JobBoards::ContentEnrichmentJob, and EmailIngestion::ImportJob (launches Playwright) have no per-class concurrency ceiling -- the only throttle is the shared queue-level thread count in config/queue.yml, so one heavy class can monopolize a whole worker pool. Apply the existing helpers to these classes.
<!-- SECTION:DESCRIPTION:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Original scope was based on an incomplete grep (only searched for the literal string 'limits_concurrency', which only appears inside application_job.rb's own method definitions, not the call sites). A proper grep for heavyweight!/mediumweight!/lightweight!/idempotent! found GeocodingJob and ContentEnrichmentJob already had limits applied -- corrected scope to the 4 job classes actually missing them: EmailImportJob (moved :light -> :heavy + heavyweight! + idempotent! -- this is the one that launches real Playwright browsers, genuinely memory-heavy, matches the session's recurring memory-pressure theme), HackerNews::FetchJobstoryJob (lightweight!), JobBoards::AuditJob (mediumweight!), JobBoards::GranularFetchJob (mediumweight!). Verified all four load and resolve queue names correctly; rubocop clean (pre-existing MethodLength/PerceivedComplexity offenses on perform bodies untouched by this change). Found and separately filed TASK-29: EmailScanJob (email_ingestion/scan_job.rb) is dead code with two broken constant references, discovered while verifying this task -- reverted an initial lightweight! addition there since applying a concurrency limit to unreachable code was pointless.
<!-- SECTION:NOTES:END -->
