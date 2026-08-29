---
id: doc-6
title: 'Wayfinder map: Reference Comparison drift loop'
type: specification
created_date: '2026-08-29 00:22'
tags:
  - 'wayfinder:map'
  - reference-comparison
---
## Destination

A locked spec — **ADR 009** (`docs/adr/009-reference-comparison-drift-and-coverage.md`) — for
how a Phase B guided session is compared against its provider's Reference Scenario, and how the
resulting *site drifted / reference incomplete / expected variation* decision is presented to
Mike and recorded durably. The map closes at "spec locked": ADR written, two architecture docs
updated, `CONTEXT.md` glossary extended, TASK-107 rewritten, implementation tickets
TASK-114..TASK-119 created. Implementation proceeds afterward as ordinary backlog work.

## Notes

Domain: `wwworkremote/core` guided-session + signature-registry subsystems. Skills consulted:
grilling, domain-modeling. This map was charted through three grilling rounds (2026-08-28); all
decisions were resolved inline, so the map is born with no open decision tickets. Execution is
**out of scope for the map** by explicit choice — it closes at spec-locked and hands off clean
whether the next session is Claude or Codex.

## Decisions so far

- **Destination artifact**: one new ADR (009) plus edits to `signature-registry.md` and
  `guided-session-flow.md`; no standalone drift-loop doc (would fragment the architecture).
- **Structural fork — materialize and extend**: a guided session materializes into an ordinary
  `Scenario` via `Scenarios::Capture.from_guided_session` on completion or an explicit "compare
  now"; `GuidedSession#scenario_id` is the ownership pointer; existing `ReferenceDiff` /
  `PromoteReference` / rake tooling is reused. Event evidence stays immutable provenance; the
  Scenario is the normalized comparison artifact. → ADR 009 "Materialize, then reuse".
- **Structural dimensions as namespaced signatures**: `field:` / `screening_question:` / `step:`
  / `commitment_boundary:` recorded as `ScenarioSignature` rows, parsed through a
  `Scenarios::SignatureKind` value object; bare provider ids are `ats_identity`; an unknown
  namespace is `unknown_namespace` (diagnostic, excluded from structural conclusions, raises in
  dev/test). Threshold to a dedicated structure model is recorded in the ADR. → TASK-114.
- **Coverage vs Drift** (two distinct findings): coverage = how much of the purpose-applicable
  reference the run reached (phase/step map, ratio derived, "unavailable" when zero applicable);
  drift = differences within the observed overlap only. A research session stopping at the first
  commitment boundary is incomplete coverage by design, and that boundary stays a visible
  applicable checkpoint. → ADR 009 "Coverage versus Drift", TASK-116.
- **Three persistent layers**: `ReferenceComparison` (immutable run, every attempt incl.
  failed/partial, `comparison_rules_version` stamped), `ComparisonFinding` (immutable, category
  drift|coverage_gap, dimension, locator, detail), `FindingDisposition` (append-only; latest
  *applicable* wins for presentation; history never overwritten). → TASK-117.
- **Five dispositions**: provider/site drift, reference incomplete/stale, expected persona
  variation, expected session-purpose variation, unresolved. Variation dispositions preserve the
  observation as evidence — never "discard". → ADR 009, `CONTEXT.md`.
- **Disposition carry-forward is suggestion-only**: match on `(dimension, locator)` scoped by
  provider + reference lineage; the new finding starts undispositioned; the source disposition id
  is recorded when a suggestion is presented or accepted. → TASK-117.
- **Per-signature provenance**: nullable `ScenarioSignature#source` jsonb, value-free breadcrumb
  only; referenced `GuidedSessionEvent`s are protected from deletion. → TASK-115.
- **screening_question locator**: versioned normalized-text hash `screening-question:v1:<sha256>`
  now; archetype identity deferred to TASK-113 (cross-reference, no dependency); rewording shows
  as lost+gained until then, an accepted limitation. → ADR 009, TASK-114.
- **`comparison_rules_version`**: frozen constant `Scenarios::ComparisonRules::VERSION`, bumped
  only when identical evidence could yield materially different findings/coverage. Row-backed
  registry threshold recorded in the ADR. → TASK-116.
- **HandshakeCheck folds in**: consumes the same `step:` / `commitment_boundary:` vocabulary,
  four outcomes (present / missing-step-not-reached=coverage / missing-step-reached=drift /
  not-applicable-to-purpose). TASK-107 rewritten from an independent enhancement into a dependent
  slice. → TASK-107.
- **Advisory only**: a comparison never authorizes, blocks, advances, or submits; automatic
  trigger idempotent on the `completed` transition; explicit trigger always a new run. → TASK-119.
- **Sandbox reference rebuilt** from a completed `application_execution` guided session through
  `from_guided_session`, promoted normally — so reference and candidates share one capture path.
  Phase A extension walkthrough demoted to a smoke check. → TASK-118.

## Ticket set (execution — ordinary backlog, not decision tickets)

| Ticket | Blocks on | Status | Proves |
|---|---|---|---|
| TASK-114 SignatureKind value object + namespace | — | ✅ Done (999474d4) | existing bare-kind behaviour unchanged; unknown namespace surfaced not hidden |
| TASK-115 `Capture.from_guided_session` + `scenario_id` + `source` | 114 | ✅ Done (7d3d2e9c) | deterministic materialization from the same immutable event evidence; no sensitive values copied |
| TASK-116 ReferenceDiff → coverage-vs-drift over markers | 114, 115 | ✅ Done (0a6cf384) | research truncation produces coverage info, not false drift |
| TASK-107 step-aware HandshakeCheck (rewritten) | 114, 116 | To Do | the four outcomes; missing-step-not-reached is coverage not failure |
| TASK-117 ReferenceComparison / ComparisonFinding / FindingDisposition | 116 | To Do | prior dispositions are suggestions with recorded lineage, never silently inherited |
| TASK-118 rebuild sandbox Greenhouse reference via guided execution session | 115 | To Do | reference contains pre- and post-boundary checkpoints |
| TASK-119 trigger + review-page findings/disposition UI (closes TASK-112 AC#6) | 116, 117, 118 | To Do | automatic comparison idempotent; manual creates a new run; neither advances or authorizes the application |

Branch: `reference-comparison-drift-loop` (not pushed). Comparison engine primitives
(`Scenarios::ReferenceDiff` / `Coverage` / `DriftAnalysis` / `ComparisonRules`) and the
`Scenarios::GuidedCapture` materialization path are landed and green; nothing wired to the
guided-session lifecycle or UI yet (TASK-119).

## Not yet specified

Nothing — the way to the destination is clear. Downstream implementation questions (exact
`step:` ordinal scheme, the normalized-text normalization algorithm, review-page layout) are
left to the implementing session per the repo's task conventions, not fog.

## Out of scope

- **Real-provider Reference Scenarios and real-provider drift.** The mechanism is
  provider-neutral but verified with the Greenhouse sandbox only. Credentialed real captures stay
  TASK-109 / TASK-83; a fresh effort once Mike has done one.
- **Archetype-keyed screening-question identity.** Belongs to TASK-113; this loop uses a
  versioned hash locator and defers.
- **Multi-persona Reference Scenario storage/matching.** The disposition vocabulary covers
  persona variation now; the sandbox reference is persona-null so nothing is blocked. Revisit
  when a real persona-bearing reference exists.
- **The execution walkthrough visualization model** (TASK-109's CT/MRI slice-stacking render).
  Separate un-charted fog; not part of the drift loop.
