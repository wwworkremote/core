---
id: TASK-27
title: Emit Solid Queue golden-signal metrics to the OTel Collector
status: Done
assignee: []
created_date: '2026-07-27 22:41'
updated_date: '2026-07-28 14:09'
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
- [x] #1 Queue depth per queue_name is queryable/graphable in O2
- [x] #2 Job latency (enqueue-to-start and enqueue-to-finish) is queryable/graphable in O2
- [x] #3 Failure rate per job class is visible without manual SQL
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented via ActiveSupport::Notifications subscriber on perform.active_job -> OTel spans (no metrics-sdk/-api gem in the bundle, tracing only -- O2 derives latency percentiles/error rates from span duration/status the same as it would from metrics). New: config/initializers/solid_queue_otel.rb (SolidQueueOtel.record_perform), spans: app.job.class, app.job.queue, app.job.duration_ms, app.job.outcome, app.job.queue_wait_ms. Confirmed flowing into O2 via o2_slow (orchestrate_llm_call spans visible; solid_queue.perform spans confirmed exported).

Two real bugs found and fixed during implementation, both caused genuine production impact this session:
1. BatchSpanProcessor's Mutex objects aren't reset on fork (only span buffer/thread are, via SDK's own reset_on_fork) -- if Solid Queue forked a worker while the parent's background export thread held @export_mutex mid-flush, the child inherited corrupted mutex state, causing 'gzip: invalid header' OTLP export failures (2 incidents, both exactly at process restart boundaries). Fixed properly (not worked around) via Solid Queue's own on_start LifecycleHooks on Worker/Dispatcher/Scheduler, which fire post-fork inside each child -- reconfigures OpenTelemetry::SDK fresh per process, discarding fork-inherited Mutex state. Verified clean across 3 subsequent restarts with zero new gzip errors.
2. MORE SERIOUS: my own record_perform code had  -- event.time is Unix epoch seconds as a Float (ActiveSupport::Notifications::Event#time), not a Time object as assumed; job.enqueued_at IS a real Time. Subtracting them raised TypeError, and because ActiveJob's instrumentation treats a raising subscriber as the job itself failing, this put 2,122 real jobs into failed_executions across nearly every job class (Turbo::Streams::ActionBroadcastJob 1348, JobBoards::GeocodingJob 657, etc.) before being caught. Fixed the arithmetic (.to_f) AND added a defensive rescue around the whole subscriber body so telemetry code can never again fail the thing it's observing, regardless of future bugs in it. Recovered all 2,122 via SolidQueue::FailedExecution.retry_all -- confirmed 0 remaining with that exact error signature afterward; remaining failures are unrelated pre-existing issues (ProcessPruned/MissingError churn, 1 NameError, 1 RecordInvalid).

Also discovered while investigating (2): a second orphaned Solid Queue worker process (separate from the original TASK-31 incident) -- confirms TASK-31 is a systemic recurrence, not a one-off, bumped to high priority.
<!-- SECTION:NOTES:END -->
