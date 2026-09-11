---
id: TASK-112.1
title: Instrument business-process health signals
status: In Progress
assignee: []
created_date: '2026-08-28 17:21'
updated_date: '2026-08-28 17:26'
labels:
  - architecture
  - observability
  - application-workflow
dependencies: []
references:
  - TASK-112
documentation:
  - docs/architecture/business-process-signals.md
  - docs/adr/007-business-process-health-signals.md
modified_files:
  - app/services/wwwr/process_signals.rb
  - config/initializers/process_signals_otel.rb
  - config/initializers/solid_queue_otel.rb
  - app/controllers/api/leads_controller.rb
  - app/services/leads/capture_service.rb
  - app/controllers/api/v0/application_statuses_controller.rb
  - app/controllers/api/guided_session_events_controller.rb
  - app/controllers/guided_sessions_controller.rb
  - docs/architecture/business-process-signals.md
  - docs/adr/007-business-process-health-signals.md
  - docs/index.md
  - spec/lib/wwwr/process_signals_spec.rb
parent_task_id: TASK-112
priority: high
type: feature
ordinal: 119000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Identify and instrument the business-truth seams that prove WWWorkRemote is processing its core job-posting-to-application loops, not merely running. Define a compact signal vocabulary, emit signals at lead capture/promotion, downstream handoff, application lifecycle, guided-session, and queue/LLM seams, and document how signal sets compose into healthy, stalled, or degraded process assertions.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Truth seams are mapped from lead observation through application lifecycle and guided-session approval
- [ ] #2 Signals are emitted without being able to fail the observed business operation
- [ ] #3 Signal names and attributes are stable, low-cardinality, and free of user content or secrets
- [ ] #4 A documented signal graph explains what healthy, stalled, and degraded combinations mean
- [ ] #5 Focused tests cover signal emission and the telemetry failure-isolation contract
<!-- AC:END -->

## Comments

<!-- COMMENTS:BEGIN -->
created: 2026-08-28 17:26
---
Mapped and instrumented the first business-truth seams: lead_observed, posting_promoted, pipeline_handoff_enqueued, queue_job_completed, guided_transition_recorded, guided_approval_decided, and application_transitioned. Added failure-safe OpenTelemetry signal adapter with bounded attributes and documented the signal graph plus functional/stalled/degraded composite interpretations. Focused cross-seam suite: 38 examples, 0 failures; extension lint and focused RuboCop clean.
---
<!-- COMMENTS:END -->
