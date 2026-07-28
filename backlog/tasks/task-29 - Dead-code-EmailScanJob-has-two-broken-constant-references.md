---
id: TASK-29
title: 'Dead code: EmailScanJob has two broken constant references'
status: To Do
assignee: []
created_date: '2026-07-28 00:21'
labels: []
dependencies: []
priority: low
ordinal: 28000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
packages/ingestion/app/jobs/email_ingestion/scan_job.rb defines a top-level EmailScanJob (Zeitwerk expects EmailIngestion::ScanJob for that path -- same class of bug as the EmailIngestion::ImportJob fix earlier this session, TASK-19) and its #perform calls EmailScanner.new.call, which also doesn't exist -- the real service is EmailIngestion::Scanner. Confirmed via grep: nothing in the app references EmailScanJob or EmailIngestion::ScanJob anywhere (not enqueued, not in recurring.yml), so unlike the ImportJob bug this one is inert rather than actively crash-looping -- but it means email scanning has no job-based entry point at all right now, if one was ever intended. Needs a product decision: fix the naming and wire it into recurring.yml (if scheduled scanning is wanted), or delete it as abandoned refactor debris.
<!-- SECTION:DESCRIPTION:END -->
