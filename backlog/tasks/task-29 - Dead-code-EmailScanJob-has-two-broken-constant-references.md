---
id: TASK-29
title: 'Dead code: EmailScanJob has two broken constant references'
status: Done
assignee: []
created_date: '2026-07-28 00:21'
updated_date: '2026-08-16 02:45'
labels: []
dependencies: []
priority: low
ordinal: 28000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
packages/ingestion/app/jobs/email_ingestion/scan_job.rb defines a top-level EmailScanJob (Zeitwerk expects EmailIngestion::ScanJob for that path -- same class of bug as the EmailIngestion::ImportJob fix earlier this session, TASK-19) and its #perform calls EmailScanner.new.call, which also doesn't exist -- the real service is EmailIngestion::Scanner. Confirmed via grep: nothing in the app references EmailScanJob or EmailIngestion::ScanJob anywhere (not enqueued, not in recurring.yml), so unlike the ImportJob bug this one is inert rather than actively crash-looping -- but it means email scanning has no job-based entry point at all right now, if one was ever intended. Needs a product decision: fix the naming and wire it into recurring.yml (if scheduled scanning is wanted), or delete it as abandoned refactor debris.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Resolved as a byproduct of TASK-19: deleted packages/ingestion/app/jobs/email_ingestion/scan_job.rb entirely (chose "delete as abandoned refactor debris" over "fix and wire up" -- TASK-19 wired the already-correct EmailIngestion::Scanner directly into the adapter registry instead, making this broken wrapper unnecessary). See TASK-19 for full details.
<!-- SECTION:FINAL_SUMMARY:END -->
