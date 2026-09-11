---
id: TASK-123
title: 'Wayfinder decision: datalake to operational read-model contract'
status: Done
assignee:
  - '@claude'
created_date: '2026-08-29 17:24'
updated_date: '2026-08-29 17:30'
labels:
  - 'wayfinder:grilling'
  - application-capture-datalake
  - 'wayfinder-map:doc-7'
dependencies: []
references:
  - >-
    backlog/docs/wayfinder/doc-7 -
    Wayfinder-map-link-to-application-capture-and-the-datalake.md
  - docs/architecture/application-question-knowledge-graph.md
  - docs/architecture/panoramic-view.md
  - >-
    backlog/tasks/task-113 -
    Build-cross-application-question-knowledge-graph-and-answer-catalog.md
ordinal: 139000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Decision ticket for wayfinder map doc-7 (backlog/docs/wayfinder/doc-7). Grilling type (HITL) — resolve with Mike via grilling + domain-modeling. Unblocked (frontier).

## Question

What is the interface between the datalake and the operational read models that consume it?

Decided in the map: the curated side unifies TASK-113's question knowledge graph and Panoramic View's `Applications::TraceEvidence` under one namespace on the `session_token` spine; cheap structural derivation stays on materialization (`complete!` -> `Scenarios::GuidedCapture`), anything richer is transform-on-read with caching, and the lake never pushes — operational models pull.

Open for this ticket:
- The namespace and module boundary — is there a `Datalake::` (or similar) module that owns manifest reading and asset access, with the question graph and `TraceEvidence` as clients? Or does each read model read the manifest directly?
- Which extractor owns what: question occurrences, screening-question archetypes, signatures, trace events, topology deltas, the "context-gathering opportunity" findings — assigned to which subsystem.
- The on-read cache: where derived-from-raw results are cached (DB rows? Rails cache? a `datalake_extractions` table?), and the invalidation rule when an extractor's logic changes (the ADR-009 `comparison_rules_version` pattern is prior art).
- What TASK-113 and Panoramic View must NOT do independently once this contract exists (so their separately-chartered work stays compatible).
- Whether the pull happens synchronously in a request or via a background job with a "still extracting" state on the view.

Output: the contract recorded on the map; notes added to TASK-113 and the Panoramic View doc pointing at it.
<!-- SECTION:DESCRIPTION:END -->

## Comments

<!-- COMMENTS:BEGIN -->
author: wayfinder
created: 2026-08-29 17:30
---
RESOLVED (grilling, 1 round). The datalake <-> operational contract:

**Module boundary -- thin store + extractor convention.** New `Datalake::` service namespace, two responsibilities only: (1) `Datalake::Bundle` -- given a session_token, parse manifest.json, enumerate asset entries (type, step/transition, sha256, bytes, captured_at), return an asset's bytes on request; read-only, knows nothing about what consumers extract. (2) `Datalake::Extractor` -- base defining `key` + `version` + `extract(bundle)`; each consuming subsystem owns its subclass. `GuidedSession#datalake_bundle` is the accessor.

**Cache + invalidation -- consumer's own domain tables + version stamp.** No shared cache table. Question occurrences -> TASK-113 question-graph tables; trace timeline -> live computed view (`Applications::TraceEvidence`, ~10s Rails.cache, mirroring `Panoramic::RuntimeEvidence` -- panoramic-view.md is explicit it is a narrator, not a write path); topology / 'context-gathering opportunity' findings -> `ComparisonFinding` rows as ADR 009 already does. Any *persisted* extraction carries a `datalake_extractor_version` column; a mismatch on read triggers re-extraction. Same discipline as ADR-009 `comparison_rules_version` -- bump only when identical raw material would yield materially different output.

**Cadence -- hybrid.** Cheap structural derivation stays exactly where it is: `Scenarios::GuidedCapture` on `complete!`, value-free event evidence, never touches raw assets. Expensive extractors (full-DOM parse, HAR walk) are ENQUEUED on first read that needs them (not synchronous in-request); the view shows a 'still extracting' state until the job lands, then reads cached rows. No eager all-extractors job on complete!.

**Scope -- guided raw bundles only.** `Datalake::` is strictly the new raw-asset layer for guided sessions, keyed by session_token. The four capture tables (ApplicationFieldObservation, ApplicationFieldMapping, ApplicationFieldAnswer, ExtensionErrorEvent) stay as-is -- trace_id-keyed, written during real applications, consumed directly. No facade over already-working inputs (signature-registry.md 'no second path'). A read model consumes {bundle when a guided session produced one} + {capture tables always}. No backfill of session_token onto historical capture rows.

**Extractor ownership:** signatures (step:/commitment_boundary:/field:/screening_question:v1:) + ATS ids -> `Scenarios::GuidedCapture`, inline on complete!, from event evidence. Question occurrences (exact wording+context) -> TASK-113 extractor (Datalake::Extractor subclass), lazy-on-read from the DOM bundle when event evidence is insufficient. Archetype clustering -> TASK-113, downstream of occurrences. Trace timeline -> `Applications::TraceEvidence`, live computed, ~10s cache, over capture tables + bundle manifest. Topology deltas + 'could capture this' findings -> `Scenarios::` (HandshakeCheck / RecordComparison extension), on materialization.

**Constraints on TASK-113 and Panoramic View:** read raw assets only through `Datalake::Bundle` (never File.read on the path); introduce no second correlation key (session_token is the spine; trace_id/application_trace_id keep their non-guided meaning); do not write to each other's tables or to ScenarioSignature; register any heavy extractor as a `Datalake::Extractor` subclass so version-stamping + the 'still extracting' state work uniformly.

**Map wording refinement:** the 'Datalake = a modality' bullet said the curated side 'unifies ... under one namespace.' More precisely: the unification is a shared spine (session_token) + shared read-only store (Datalake::Bundle) + shared extractor convention (Datalake::Extractor). Consumers keep their own namespaces (Applications::TraceEvidence, the TASK-113 namespace) and their own tables. Map updated.

No new tickets surfaced. Pending: a pointer note on docs/architecture/panoramic-view.md + a note on TASK-113 -- deferred until the working tree is off the concurrent research/mv3-capture-capabilities branch.
---
<!-- COMMENTS:END -->
