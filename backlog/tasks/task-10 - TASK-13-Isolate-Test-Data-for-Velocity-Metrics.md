---
id: TASK-10
title: 'TASK-13: Isolate Test Data for Velocity Metrics'
status: Done
assignee: []
created_date: '2026-05-23 12:57'
updated_date: '2026-08-16 12:44'
labels: []
dependencies: []
priority: medium
ordinal: 10000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The 'Charts::Data::Sources' spec reports 3 registrations instead of 1. This is caused by test data pollution (side effects from other tests or shared test data setup). We need to isolate test data to ensure metrics are reliable.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Velocity metrics in 'Charts::Data::Sources' accurately report 1 source registration.
- [ ] #2 Test environment is correctly isolated and avoids data pollution from other tests.
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Duplicate of TASK-35, closing without separate work. Same spec (spec/requests/charts/data/sources_spec.rb / Charts::Data::Sources), same symptom ("expected 1, got 3"), same underlying cause -- TASK-35 (filed 2026-08-10, three months after this one) actually root-caused it: bin/verify_ingestion (called by bin/smoke) writes real Source rows to the test DB outside any RSpec transaction, so they never roll back. TASK-35 has the accurate root cause, concrete acceptance criteria, and is the one to pick up. This task's title also carries a stale embedded "TASK-13" self-reference from whatever bulk-import created TASK-9/10/11/12 -- noted here in case other tasks from that same batch have the same mislabeling.
<!-- SECTION:FINAL_SUMMARY:END -->
