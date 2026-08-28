# ADR 006: Use BPMN-lite Mermaid as the Guided Session Validation Scheme

## Status
Accepted

## Context

The supervised application session crosses actor decisions, extension
observations, durable events, provider-specific subflows, and approval gates.
The existing AASM state machines describe lifecycle facts well, but they do
not express the whole actor/system flow or parallel review obligations. A full
workflow engine would add operational infrastructure and duplicate state that
already belongs to ActiveRecord and AASM.

## Decision

Maintain a BPMN-lite flow as a Mermaid diagram in
`docs/architecture/guided-session-flow.md`. It is the reviewable validation
scheme for guided-session implementations:

- **User Task** means Mike supplies intent or authorizes a consequential move.
- **Service Task** means the system observes, proposes, constructs, or records;
  it never grants itself approval.
- **Gateway** means a classification or human decision controls progression.
- **Intermediate Event** means a meaningful transition is persisted in the
  guided-session timeline.
- The four pump-track phases remain the stable top-level cycle; provider
  subflows live inside them.

`GuidedSession` and `GuidedSessionEvent` remain the durable implementation
seam. AASM continues to model entity lifecycle facts, while this BPMN-lite
scheme validates ordering, handoffs, approval gates, and loop-back behavior.
No Camunda, Temporal, or native AASM/BPMN runtime is introduced by this ADR.

## Consequences

- Every new guided-session transition can be located in a phase and assigned
  an actor/system role before code is added.
- Reviewers can check that unknown, ambiguous, and irreversible transitions
  reach Mike instead of silently advancing.
- Mermaid gives the local docs site a living design artifact without a second
  runtime or deployment concern.
- The diagram is a validation scheme, not proof of runtime behavior; focused
  tests must still exercise the public interfaces represented by each seam.
- Playback state is a durable viewing cursor so a session can be handed off
  and resumed without implying that the next provider action is authorized.
- If the diagram repeatedly requires engine semantics that ActiveRecord,
  `GuidedSessionEvent`, and AASM cannot express locally, that is evidence for a
  new architecture decision—not permission to smuggle in a workflow engine.

## Rejected Alternatives

- **Camunda or Temporal:** adds infrastructure and a second source of truth for
  a single-user local-first workflow.
- **Native AASM/BPMN integration:** conflates lifecycle state with the richer
  actor/system event flow and approval obligations.
- **Unstructured prose only:** makes phase ordering and safety gates harder to
  review or validate against implementation.
