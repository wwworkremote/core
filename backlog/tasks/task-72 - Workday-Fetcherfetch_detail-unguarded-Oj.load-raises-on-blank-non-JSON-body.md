---
id: TASK-72
title: 'Workday::Fetcher#fetch_detail unguarded Oj.load raises on blank/non-JSON body'
status: To Do
assignee: []
created_date: '2026-08-19 15:04'
labels: []
dependencies: []
references:
  - packages/ingestion/app/services/workday/fetcher.rb
priority: low
type: bug
ordinal: 85000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found by a pipeline-health audit pass. `packages/ingestion/app/services/workday/fetcher.rb:125` calls `Oj.load(response.body)` with no guard for a blank/non-JSON response body. Recurring specifically for source_id 43 (`wd1/OneMainCareers/myhrhome`) -- failed Aug 17 and again Aug 19 13:01 UTC with `Oj::ParseError: unexpected character (after ) at line 1, column 1`. Other Workday tenants aren't affected, so this may be tenant-specific (e.g. that board occasionally returns an empty/HTML error page instead of JSON) rather than a universal parsing bug. Fix: guard against blank/non-JSON body before parsing, log and skip rather than raise.
<!-- SECTION:DESCRIPTION:END -->
