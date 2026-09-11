# ADR 007: Model Functional Health as Business-Process Signal Sets

## Status
Accepted

## Context

Process liveness is not product health. Puma, Solid Queue, and OpenTelemetry
can all report healthy while a lead is not promoted, a handoff is not enqueued,
an LLM result is unusable, or an application is waiting at an unrecorded human
decision. The system needs instrumentation at the seams where business truth
changes, then a way to interpret sets of signals as a process graph.

## Decision

Emit a compact `Wwwr::ProcessSignals` fact at each business-truth seam and
export it through the existing OpenTelemetry pipeline as a named span. Use
stable signal names and bounded attributes only. Keep the signal interface
small enough that controllers, services, jobs, and adapters can emit facts
without knowing how they will be aggregated.

Interpret process health from ordered signal sets rather than individual
heartbeat metrics. A missing downstream signal identifies the stalled handoff;
an error outcome identifies degradation; a pending guided approval identifies a
valid human hold, not a system failure.

## Consequences

- Functional health follows the actual job-posting-to-application process.
- Existing queue and LLM telemetry becomes meaningful when joined to business
  handoff signals.
- Signal emission has no durable business side effects and must be failure-safe.
- High-cardinality content is excluded; detailed evidence remains in the
  existing domain records and guided-session event timeline.
- The graph can later drive dashboards, alerts, or trace queries without
  changing the business modules that emit facts.

## Rejected alternatives

- **Process liveness only:** misses broken handoffs behind healthy processes.
- **One global health score:** hides the first missing edge and conflates a
  valid human pause with failure.
- **Raw request logs as the model:** lacks stable business vocabulary and
  cannot distinguish transport success from process completion.
