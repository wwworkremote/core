# ADR 005: Preserve Intent Through Supervised Application Sessions

## Status
Accepted

## Context

WWWorkRemote is intended to learn the job-posting-to-application process from
Mike's judgment, not merely collect browser telemetry. The same broad phases
recur across providers, while the important differences are often subtle:
handoffs, optional-but-wise choices, state changes, reversibility, and actions
that require approval.

A fully autonomous application agent would hide those distinctions and could
turn a clean-looking run into an unreviewed commitment. A passive recording
would preserve events without explaining intent. Neither is sufficient to
train a trustworthy assistant.

## Decision

The durable unit of learning is a **supervised application session**: one
pump-track lap from a copied job-posting URL through the next meaningful
outcome. A session records both observable events and actor annotations:

- the current pump-track phase
- the action and resulting state change
- the actor's intent and available alternatives
- whether the action is required, optional, recommended, reversible,
  irreversible, or approval-gated
- the evidence and provenance supporting the next move
- Mike's explicit approval, denial, edit, or interruption where required

Automation has bounded agency. It may replay deterministic, well-understood
steps, but it must pause at unknown, ambiguous, or irreversible transitions.
Final application submission always requires explicit human approval. A
successful run never silently promotes its behavior into the reference model.

A session declares a purpose. **Application research** may enter an employer's
flow, inspect its sequence and questions, and record reversible state without
trying to submit. **Application execution** may prepare an application under
supervision. Purpose does not grant blanket authority: transmitting sensitive
data, creating consequential persistent provider state, accepting terms, and
final submission are commitment boundaries classified and approved at the
individual transition.

The session transition is:

`session_(n+1) = MikeDecision(Present(Record(Resolve(Intake(session_n)))))`

The system may propose the next move; Mike remains the actor who authorizes
the move.

The ordering and role contract for these transitions is sketched in the
[BPMN-lite Guided Session Flow](../architecture/guided-session-flow.md), whose
Mermaid diagram serves as the validation scheme for implementation.

## Consequences

- A localhost entry flow should accept a copied posting URL and create a
  durable guided session.
- Browser capture must preserve meaningful transitions and intent, not every
  low-level event indiscriminately.
- The application UI should show the current phase, next proposed move,
  evidence, and approval state.
- Training and replay should be grounded in Mike-authored annotations and
  reference scenarios, not inferred solely from frequency.
- Privacy and security boundaries remain explicit: credentials and sensitive
  values are never treated as general-purpose training material.

## Rejected Alternatives

- **Opaque autonomous submission:** unsafe at irreversible boundaries and loses
  Mike's judgment.
- **Employee-style telemetry capture:** records behavior without intent,
  meaning, or approval semantics.
- **Provider-specific top-level workflows:** duplicates the shared pump-track
  phases instead of isolating only genuinely unique subflows.
