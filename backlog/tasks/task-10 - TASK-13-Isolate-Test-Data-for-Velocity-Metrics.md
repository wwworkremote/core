---
id: TASK-10
title: 'TASK-13: Isolate Test Data for Velocity Metrics'
status: To Do
assignee: []
created_date: '2026-05-23 12:57'
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
