---
id: TASK-9
title: 'Operational: Smoke Test Automation'
status: Done
assignee: []
created_date: '2026-05-06 21:34'
updated_date: '2026-08-16 14:51'
labels:
  - infrastructure
  - ci
dependencies: []
priority: medium
ordinal: 9000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Convert manual smoke tests (Email Ingestion, AI Inference check) into a formal bin/smoke script to ensure CI coverage for end-to-end flows.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 bin/smoke exists and orchestrates AI Inference (LLM) and Operational Ingestion checks
- [x] #2 bin/smoke also covers Email Ingestion, the third manual smoke test named in the original description
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Was already 2/3 done (bin/smoke existed with LLM + Ingestion checks, likely from earlier work never linked back to this task) -- the named-but-missing piece was Email Ingestion. Added bin/verify_email_ingestion (runs EmailIngestion::Scanner against ~/.wwworkremote/{source}/*.eml, reports per-source file counts; zero files is a healthy pass since mail presence is intermittent, not guaranteed) and wired it into bin/smoke as step 3/3.

Applied this session's own bin-script-conventions guidance: EmailIngestion::FileClaim does a real, non-transactional EmailImportRecord.create! per file, so the new script refuses to run under RAILS_ENV=test (same guard as bin/verify_board), preventing a TASK-35-class test-DB pollution bug from day one instead of discovering it later.

Verified live: ran bin/verify_email_ingestion directly against the real ~/.wwworkremote directories (531 real .eml files found across indeed/linkedin/adzuna) -- completed without error. Full bin/smoke run halted at step 1 (LLM embeddings check) due to an unrelated, pre-existing local server config issue (embed server not started with --embeddings) -- a zdots-managed service concern, not a bug in this repo; noted but intentionally not touched.
<!-- SECTION:FINAL_SUMMARY:END -->
