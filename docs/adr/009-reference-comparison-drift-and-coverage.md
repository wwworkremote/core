# ADR 009: Reference Comparison — Drift and Coverage from Guided Sessions

## Status
Accepted

## Context

A [Reference Scenario](../architecture/signature-registry.md#reference-scenario--the-golden-master-not-a-platonic-ideal)
is the golden-master flow for a provider. A [Guided Session](../architecture/guided-session-flow.md)
records a supervised lap through a real (or sandbox) application. The remaining
seam — flagged as the next action in three separate handoffs and as TASK-112
AC #6 — is comparing one against the other: *did this run diverge from what we
believe a correct flow looks like, and if so, is the site drifting or is our
reference incomplete?*

Two worlds exist that have never been connected:

- `Scenario` / `ScenarioSignature` / `Scenarios::ReferenceDiff` / `ReferenceScenario`
  / `Scenarios::PromoteReference` / `rake scenarios:reference_diff` — built around
  ATS identity signatures (`job_post_id`, `ats_application_id`) captured from
  HAR/DOM text.
- `GuidedSession` / `GuidedSessionEvent` — records value-free form structure,
  screening-question structure, phase transitions, and approval decisions, with
  the event `evidence` jsonb as immutable provenance.

`Scenarios::HandshakeCheck` is flat: `:required_after_submit` is checked as plain
`:required` because nothing knows which step a run reached. An
`application_research` session deliberately stops at the first commitment
boundary, so it will always "lack" post-submit signatures — that is not drift.

## Decision

### Materialize, then reuse

On the first transition of a `GuidedSession` to `completed`, and on an explicit
"Compare to Reference" action from the review page, the session is materialized
into an ordinary `Scenario` via a new `Scenarios::Capture.from_guided_session`
entry path that consumes the value-free event evidence directly. Raw DOM/HAR
retention is never a prerequisite.

- `GuidedSession#scenario_id` is the ownership pointer to the materialized result.
- `ScenarioSignature#source` (nullable jsonb) carries a value-free provenance
  breadcrumb: `{ "guided_session_event_id": N, "extracted_from": "evidence.fields[2].key" }`.
  Permitted keys and source-path syntax are validated at write time. A source
  event referenced by any signature must not be deletable or prunable.
- The materialized `Scenario` is a valid candidate for `Scenarios::PromoteReference`;
  the promotion workflow itself is unchanged.

The event evidence remains the immutable full-fidelity provenance; the `Scenario`
is the normalized comparison artifact. Materialization from the same immutable
evidence is deterministic.

### Structural dimensions as namespaced signatures

Field structure, screening-question structure, step order, and commitment
boundaries reached are represented as `ScenarioSignature` rows under a controlled
namespace, parsed and validated through a `Scenarios::SignatureKind` value object:

| Namespace | Example kind | Meaning |
|---|---|---|
| `field` | `field:work_authorization` | a form field present in the observed structure |
| `screening_question` | `screening-question:v1:<sha256>` | a screening question, keyed by versioned normalized-text hash |
| `step` | `step:resolution.2` | an ordered checkpoint in the flow |
| `commitment_boundary` | `commitment_boundary:submit` | a classified commitment boundary encountered |
| *(bare)* | `job_post_id` | an ATS identity signature — namespace `ats_identity` |

Ordering stays in the existing `first_observed_at` / `step` columns (set from the
source event's `occurred_at`); full detail stays in provenance evidence. No
consumer splits kind strings directly — `ReferenceDiff`, `HandshakeCheck`,
coverage, and presentation all go through `Scenarios::SignatureKind`.

An unrecognized namespace is classified `unknown_namespace`, not silently treated
as a bare ATS identity: it emits an observable diagnostic and is excluded from
structural conclusions. Development and test raise.

`Scenarios::ReferenceDiff` extends to these namespaced signatures using its
existing gained / lost / reordered logic.

### Coverage versus Drift

Comparison is overlap-aware and commitment-boundary-aware.

- **Reached Scope** = the portion of the reference process a session actually
  reached, bounded by its `purpose` and where it stopped.
- **Drift** = `Δ(guided_signatures, reference_signatures ∩ Reached Scope)` —
  differences *within* the observed overlap.
- **Coverage** = `applicable checkpoints reached / applicable reference checkpoints`.
  A checkpoint is an ordered distinct reference `step:` marker, rendered as
  reached / not reached / not applicable. For `application_research`, the first
  `commitment_boundary:` checkpoint stays **applicable and visible** as the
  intentional stopping point; checkpoints that require crossing it are not
  applicable. If there are zero applicable checkpoints, coverage is reported as
  **unavailable** — never 0% or 100%. The phase/step map, not the ratio, is the
  primary display.

### Three persistent layers

Events establish what happened; findings establish what the comparison inferred;
dispositions record what Mike decided.

- **`ReferenceComparison`** — one immutable row per comparison run, including
  failed or partial attempts (operational diagnosis matters). `belongs_to
  :guided_session`, `belongs_to :scenario`, `belongs_to :reference_scenario`,
  plus `provider` and reference id retained as run-time facts.
  `comparison_rules_version` stamped from `Scenarios::ComparisonRules::VERSION`.
  `coverage` jsonb is a versioned snapshot, not queried as the canonical process
  model. `ran_at`.
- **`ComparisonFinding`** — immutable result of one run. `category`
  (`drift` | `coverage_gap`), `dimension` (`signature_kind` | `field_structure`
  | `screening_question` | `step_order` | `commitment_boundary` |
  `provider_structural`), `locator` (stable string identifying *what* diverged),
  `detail` jsonb.
- **`FindingDisposition`** — append-only human judgment. `value` ∈ { provider/site
  drift, reference incomplete or stale, expected persona variation, expected
  session-purpose variation, unresolved }, `rationale`, `reviewer` (stable actor
  reference where available, with a captured display label), `resume_persona_id`
  (nullable), `created_at`. The latest *applicable* disposition wins for
  presentation; every prior disposition stays a first-class record and is never
  overwritten.

A new run's finding that matches a prior `(dimension, locator)` — scoped by
provider and reference lineage — surfaces the prior disposition as a **suggested
default only**. The new finding starts undispositioned and requires
confirmation. The source disposition id is recorded when a suggestion is
presented or accepted, so decision lineage stays explainable.

### Advisory only

A `ReferenceComparison` never authorizes, blocks, advances, or submits an
application — it mirrors the playback cursor's "viewing, not authorization"
separation. The automatic trigger is idempotent for the `completed` transition
so retries cannot create duplicate automatic runs; explicit comparison always
creates a new run.

### HandshakeCheck folds in

`Scenarios::HandshakeCheck` consumes the same `step:` / `commitment_boundary:`
vocabulary and reports each expected kind as one of:

- required and present
- **missing, but the required step was not reached** — coverage information, not
  a failure
- **missing after the required step was reached** — drift / failure
- not applicable to this session purpose

TASK-107 becomes an implementation slice of this loop rather than a parallel
design.

### Sandbox reference rebuilt

The sandbox Greenhouse Reference Scenario is rebuilt from a completed
`application_execution` guided session captured through
`Scenarios::Capture.from_guided_session`, then promoted through the normal
workflow — so candidate and reference share one capture path and one structure.
The Phase A extension walkthrough (TASK-105) stays a useful smoke check but no
longer defines the canonical structural reference. The sandbox submission stays
unmistakably synthetic and isolated; this does not relax commitment-boundary
rules for real providers.

## Consequences

- New models: `ReferenceComparison`, `ComparisonFinding`, `FindingDisposition`.
  New value object: `Scenarios::SignatureKind`. New constant:
  `Scenarios::ComparisonRules::VERSION` (bump only when identical evidence could
  produce materially different findings or coverage; not for formatting,
  presentation, or performance changes).
- New column `ScenarioSignature#source` (nullable jsonb). New column
  `GuidedSession#scenario_id` (nullable).
- Screening-question drift is deliberately coarse until TASK-113: a reworded
  question appears as a lost + gained pair. The versioned locator
  (`screening-question:v1:<sha256>`) and preserved value-free structural evidence
  make a later migration to archetype-keyed identity a data migration, not a
  redesign.
- **Threshold — dedicated structure model:** extract structural signatures into
  their own model only when they need independent lifecycle, relationships, or
  querying the signature registry can no longer express cleanly. Until then the
  namespaced-kind representation reuses capture, diff, promotion, and tooling.
- **Threshold — row-backed rules registry:** move `ComparisonRules` from a
  constant to a table only if rules must change without a deploy, or vary per
  provider.
- Scope: the mechanism is provider-neutral but verified with the Greenhouse
  sandbox only. Credentialed real-provider references remain TASK-109 / TASK-83
  work and do not block TASK-112 AC #6.

## Rejected Alternatives

- **Parallel comparison path over `GuidedSessionEvent`s without materializing a
  `Scenario`:** loses reuse of `ReferenceDiff` / `PromoteReference` / the rake
  task / tooling, and leaves two capture shapes that can drift apart.
- **A dedicated `ScenarioStructure` model now:** premature; the registry
  expresses structure cleanly via namespaced kinds. Captured as a threshold
  above instead.
- **Encoding every semantic in one opaque `kind` string:** scatters string
  splitting through business logic. `Scenarios::SignatureKind` is the parser
  boundary.
- **Auto-inheriting a prior disposition on a matching finding:** silently ships a
  stale human judgment past a comparison-rules change.
- **Comparison as a gate on the session:** violates the advisory/presentational
  principle and the playback-cursor separation.
- **Archetype-keyed screening-question locators now:** a hard dependency on the
  unbuilt TASK-113. Deferred behind a versioned hash locator.
- **Unknown namespaces degrading to bare ATS identity in production:** conceals
  vocabulary drift. Classified `unknown_namespace` with a diagnostic instead.
