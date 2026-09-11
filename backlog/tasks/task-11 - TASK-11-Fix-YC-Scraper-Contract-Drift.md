---
id: TASK-11
title: 'TASK-11: Fix YC Scraper Contract Drift'
status: Done
assignee: []
created_date: '2026-05-23 12:57'
updated_date: '2026-08-16 14:32'
labels: []
dependencies: []
priority: high
ordinal: 11000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The YC scraper contract is failing with a 406 status and missing 'data-page' attribute, likely due to external API schema drift. This issue needs to be diagnosed and fixed to restore ingestion data integrity.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 YC Scraper correctly handles HTTP response.
- [x] #2 'data-page' attribute is successfully extracted.
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Stale -- already fixed 3 weeks before this audit, just never closed. Commit c1ca2528 (2026-07-28, "fix: OTel fork-safety, freshness bug, TASK-11/TASK-12, commit-msg hook") added the missing Accept header to Yc::Scraper::REQUEST_HEADERS with a code comment explicitly citing TASK-11 (packages/ingestion/app/services/yc/scraper.rb:9-13): workatastartup.com returns 406 without an explicit Accept header, which bare Faraday/Ruby requests don't send by default.

Verified live 2026-08-16: both examples in spec/contracts/yc_spec.rb (real HTTP request against https://www.workatastartup.com/jobs, not mocked) pass -- 200 status, data-page attribute present, JSON parses with a valid jobs array.
<!-- SECTION:FINAL_SUMMARY:END -->
