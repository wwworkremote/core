---
id: TASK-19
title: >-
  Fix or redesign scheduled email-source sync
  (sync_emails_indeed/adzuna/linkedin)
status: To Do
assignee: []
created_date: '2026-07-27 17:59'
labels: []
dependencies: []
references:
  - config/recurring.yml
  - app/jobs/email_import_job.rb
  - packages/ingestion/app/jobs/email_ingestion/scan_job.rb
  - packages/ingestion/app/services/email_ingestion/scanner.rb
  - config/initializers/ingestion_adapters.rb
priority: high
ordinal: 18000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
config/recurring.yml scheduled EmailIngestion::ImportJob (with a source-name arg like "indeed") every hour for Indeed/Adzuna/LinkedIn, but that class never existed as such -- Zeitwerk expected it from packages/ingestion/app/jobs/email_ingestion/import_job.rb, which actually defined a broken top-level EmailImportJob calling a nonexistent EmailImporter constant (dead code from commit 5b0c2bc, 'modularize ingestion logic', an apparently-abandoned refactor). Solid Queue treats any unresolvable recurring class as fatal at boot, so the jobs process couldn't start at all until these three entries were disabled. The LIVE EmailImportJob (app/jobs/email_import_job.rb, wired into config/initializers/ingestion_adapters.rb and packages/ingestion/app/services/email_ingestion/scanner.rb) takes a record_id and processes one already-created EmailImportRecord -- it has no source-driven 'scan and import everything from source X' mode, so it can't just be swapped in as-is. Needs a product decision: either (a) build a per-source scan+enqueue job that finds pending EmailImportRecords for a source and enqueues the live EmailImportJob for each, or (b) finish the abandoned per-source EmailImporter design properly. Until resolved, scheduled email ingestion for these three sources does not run.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Decide the intended design: per-source scan+enqueue wrapper around the live EmailImportJob, vs finishing the EmailImporter/EmailIngestion::Importer per-source pipeline
- [ ] #2 config/recurring.yml sync_emails_indeed/adzuna/linkedin re-enabled pointing at a real, correctly-Zeitwerk-named class
- [ ] #3 packages/ingestion/app/jobs/email_ingestion/scan_job.rb reviewed -- same abandoned-refactor pattern (defines top-level EmailScanJob instead of EmailIngestion::ScanJob per its path) and is currently unreferenced anywhere; fix or remove
- [ ] #4 bin/dev jobs process boots cleanly with all recurring tasks valid
<!-- AC:END -->
