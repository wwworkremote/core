---
id: TASK-27
title: Emit Solid Queue golden-signal metrics to the OTel Collector
status: To Do
assignee: []
created_date: '2026-07-27 22:41'
labels: []
dependencies: []
priority: medium
ordinal: 26000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
config/initializers/opentelemetry.rb only registers Rails/PG/Faraday/RubyLLM instrumentation -- no Solid Queue-specific spans or metrics exist, so nothing about queue health flows to the OTel Collector -> O2. mission_control-jobs (already in Gemfile, mounted at /jobs) gives live saturation (queue depth) and error (failed job list) snapshots, but no throughput-rate or latency-percentile history -- can't answer 'was the queue backed up at 3am' without manual SQL archaeology (done repeatedly this session, e.g. 2026-07-27 backlog investigation). Add an ActiveSupport::Notifications-based hook (or a small recurring job) that emits: (1) queue depth per queue_name (solid_queue_ready_executions count grouped by queue), (2) job latency since enqueued (finished_at - created_at, or claimed_at - created_at for queue wait time specifically), (3) failure rate per job class, as OTel metrics/spans to the existing collector. This gets real percentile latency and throughput trend in O2 for free instead of a bespoke dashboard.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Queue depth per queue_name is queryable/graphable in O2
- [ ] #2 Job latency (enqueue-to-start and enqueue-to-finish) is queryable/graphable in O2
- [ ] #3 Failure rate per job class is visible without manual SQL
<!-- AC:END -->
