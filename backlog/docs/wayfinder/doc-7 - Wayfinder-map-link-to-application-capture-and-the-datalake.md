---
id: doc-7
title: 'Wayfinder map: link-to-application capture and the datalake'
type: specification
created_date: '2026-08-29 17:23'
updated_date: '2026-08-29 20:46'
tags:
  - 'wayfinder:map'
  - 'wayfinder:closed'
  - datalake
  - application-workflow
---
## Destination

A locked architecture spec for the path from **one job-posting link -> a recorded guided
session -> a supervised application**, and the layered **datalake** that path feeds. The
spec deliverable is: one new ADR, a new `docs/architecture/datalake.md`, edits to
`panoramic-view.md` / `signature-registry.md` / `application-question-knowledge-graph.md`,
`CONTEXT.md` glossary extensions, and implementation `TASK-*` tickets created. The map
closes at "spec locked"; implementation proceeds afterward as ordinary backlog work.
TASK-112 (guided recorder AC#2-5), TASK-113 (question knowledge graph), and Panoramic View
(design doc) are **named dependencies at their existing scope**, not re-planned here.

## Notes

Domain: `wwworkremote/core` guided-session + signature-registry + question-graph
subsystems. Skills every session consults: grilling, domain-modeling. Standing constraints:
**Bounded Agency** (advisory only -- nothing charted here authorizes, fills, or submits an
application); **Intent Is First-Class**; the raw datalake layer is **machine-local,
git-ignored, never synced or committed** (Mike's own job-search data -- not PHI, but
PII-bearing). Charted 2026-08-29 across four grilling rounds; most decisions were resolved
inline (below). Execution is out of scope for the map -- it hands off clean at spec-locked
whether the next session is Claude or Codex.

**Status: CLOSED / SPEC-LOCKED (2026-08-29).** All decision tickets resolved and the spec
written -- see "Spec-lock deliverables" below. Remaining work is ordinary backlog
implementation: TASK-126, TASK-127, TASK-128, TASK-129, TASK-130.

## Decisions so far

- **Destination artifact**: a locked spec (ADR + `datalake.md` + doc edits + `CONTEXT.md` +
  implementation `TASK-*`), same shape as the doc-6 / ADR 009 drift-loop map. Not a built
  feature.
- **Scope**: only the new connective layer -- the `JobPosting`->session entry seam, the
  correlation spine, the datalake modality, the ATS-topology extension, the
  automation-readiness loop, and the wwworkremote.localhost legibility surfaces. TASK-112 /
  TASK-113 / Panoramic View keep their scope and become dependencies.
- **Entry seam**: `GuidedSession belongs_to :user_job_posting` (nullable). A "Start
  supervised application" affordance on `job_postings/show` (creates a `UserJobPosting` if
  none exists). Starting or completing a session never auto-changes `UserJobPosting` AASM
  state -- completion may *propose* a transition as a `HumanTask`. Advisory, same discipline
  as Reference Comparison. Implementation: **[TASK-129](task-129)**.
- **Correlation spine**: promote `GuidedSession#session_token` to the run super-identifier.
  The extension already carries `?guided_session_token=`; it stamps that token onto the four
  `trace_id` capture-table rows it writes during a guided session and onto the materialized
  `Scenario`. `application_trace_id` / `scenario_token` stay as-is for non-guided paths.
  Implementation: **[TASK-129](task-129)**.
- **Datalake = a modality, not a product name**: a flexible schema-on-read landing zone
  aggregating heterogeneous recorded assets (DOM, HAR, screenshots) *and* extracted
  questions/answers, organized tidily so context extracts cleanly into the operational
  system. The "unification" of TASK-113's question graph and Panoramic View's `TraceEvidence`
  is **a shared spine (`session_token`) + a shared read-only store (`Datalake::Bundle`) + a
  shared extractor convention (`Datalake::Extractor`)** -- the consumers keep their own
  namespaces and their own tables. -> see the contract decision below.
- **Datalake <-> operational contract** ([Datalake <-> operational read-model contract](task-123),
  resolved): thin `Datalake::` store (`Datalake::Bundle` = manifest + asset bytes, read-only;
  `Datalake::Extractor` = `key`/`version`/`extract(bundle)` base, one subclass per consumer).
  No shared cache table -- each consumer persists into its own domain tables with a
  `datalake_extractor_version` stamp (mismatch on read -> re-extract, ADR-009
  `comparison_rules_version` discipline). Cadence is hybrid: cheap structural derivation
  stays inline on `complete!` (`Scenarios::GuidedCapture`, value-free event evidence, never
  touches raw assets); expensive extractors are enqueued on first read and the view shows a
  "still extracting" state. `Datalake::` covers **guided raw bundles only** -- the four
  `trace_id`-keyed capture tables stay as-is, consumed directly; a read model consumes
  `{bundle when present} + {capture tables always}`; no `session_token` backfill onto
  historical capture rows. Pointer notes recorded in `docs/architecture/panoramic-view.md`
  and on TASK-113.
- **Extension capture capabilities** ([Chrome MV3 capture capabilities for the raw datalake layer](task-121),
  resolved): the greedy raw scope (DOM per transition + full HAR incl. response bodies +
  screenshot per transition) is achievable now with the permissions the extension already
  holds (`activeTab`, `debugger`, named host list) -- no new install warning. DOM via
  content-script `Element.getHTML` (open shadow roots + same-origin frames only); response
  bodies and full-page screenshots only via `chrome.debugger` + CDP, which carries a per-tab
  "started debugging this browser" banner and yields when DevTools opens on the tab. Closed
  shadow DOM, a content-script resource inliner, `<all_urls>`, and `webRequest` are dropped
  for v1. Debugger-sourced captures must be individually optional; capture gaps
  (cross-origin frames, closed roots, post-detach transitions) recorded explicitly in the
  bundle `manifest.json`. Findings: `docs/research/mv3-capture-capabilities.md`.
- **Guided-recorder raw-capture seam** ([Guided-recorder raw-capture seam for the datalake](task-122),
  resolved): the extension POSTs one asset at a time to a new
  `POST /api/v0/guided_sessions/:session_token/datalake_assets` endpoint (mirrors the events
  endpoint, `Rails.env.local?` gate, `API_FETCH` relay); Rails writes it under
  `data/datalake/sessions/<session_token>/` and owns `manifest.json`. One capture per emitted
  `GuidedSessionEvent` (piggybacks on TASK-112's transition judgement, 1:1 with the timeline).
  `application_execution` attaches `chrome.debugger` for full HAR bodies + full-page
  screenshots; `application_research` stays light (content-script DOM + `captureVisibleTab`,
  no banner); Mike can override. Capture failures emit `EXTENSION_ERROR` + a manifest gap
  entry, never break the session. Implementation is **[TASK-126](task-126)** (depends on
  TASK-112), a new task -- TASK-112's scope is unchanged. The prune job / curation report
  and the `Datalake::` read side are out of scope for TASK-126.
- **Automation-readiness corpus + eval harness** ([Automation-readiness corpus and eval-harness shape](task-124),
  resolved): readiness class lives in an append-only `archetype_readiness_assessments` table
  (FindingDisposition-style, latest applicable wins, merge/split carries forward as a
  suggestion). Verdicts land in a value-free `answer_proposal_verdicts` table (sha256 hashes
  + edit_distance + `strategy_source` canned/template/ai + verdict accepted/edited/declined;
  no answer text). The harness replays the same `LLM::AnswerGenerator.call` path
  (`CannedAnswers` + `ApplicationAnswerTemplate` + `PromptBuilder`/prompt constants + the
  configured `answer_generation` model) and reports verbatim-acceptance rate + median edit
  distance split by strategy -- **advisory only, never flips an archetype to auto-fill**.
  Corpus = per-archetype JSONL under `data/datalake/corpus/` (git-ignored). Suggested-default
  inputs: occurrence frequency, historically-winning strategy source, median edit distance,
  sample-size floor. Implementation is **[TASK-127](task-127)** (depends on TASK-113; touches
  the sidepanel TASK-78 flow).
- **wwworkremote.localhost harness-legibility surfaces**
  ([Wayfinder decision: wwworkremote.localhost harness-legibility surfaces](task-125),
  resolved): per-posting **title badge + aside card** on `job_postings/show` showing the
  furthest state reached (none / in_progress / recorded / compared), derived from the
  `GuidedSession`s linked to the posting's `UserJobPosting` -- no new column. Per-company
  **stat block + posting-list marks** on `companies/show`; "processed through the harness" is
  defined **once** (`UserJobPosting` with >= 1 `GuidedSession` at `status = completed`) and
  reused everywhere. Navigation: contextual entry via the aside card + a
  `GET /guided_sessions` **index linked from the Admin/Tools menu** (not primary nav);
  `guided_sessions#show` is the **single canonical per-run view** and Panoramic View's planned
  "View full trace" link resolves there for guided runs. Readiness rollups (TASK-124/127) are
  **deferred** off these surfaces. Coin **Harness** / **Processed through the harness** in
  `CONTEXT.md` at spec-lock. Implementation is **[TASK-128](task-128)** (needs the entry seam).
- **Raw asset scope**: greedy -- DOM snapshot per meaningful transition, full HAR (incl.
  response bodies), screenshots per transition, plus the value-free field structure and
  observed Q&A.
- **Raw layer protection**: unencrypted on the local filesystem, git-ignored, never
  synced/committed/uploaded -- a documented boundary. Curated extraction stays
  value-free/structural. The raw bundle gets a short grace window then becomes prune-eligible,
  precisely because it is the PII-bearing layer.
- **Storage layout**: one directory per `session_token` under a git-ignored repo path, with
  a `manifest.json` enumerating every asset (type, step/transition, sha256, captured_at,
  bytes) and the assets alongside as plain files. New asset types = new manifest entries, no
  migration.
- **Extraction**: cheap structural derivation stays on materialization (`complete!` ->
  `GuidedCapture`). Anything richer is transform-on-read -- curated read models query the
  manifest + assets lazily and cache. The lake never pushes; operational models pull.
- **ATS topology**: extend the Signature Registry. `SIGNATURE_EXPECTATIONS` (per-provider) +
  the (now to-be-built) `TenantIdentity` (per-employer instance) + Reference Scenario
  (per-provider golden master) together *are* the topology. "Opportunities to gather more
  context" become a new finding category on `HandshakeCheck` / comparison output --
  `optional-and-missing` signatures and un-mapped fields surface as ranked, reviewable
  "could capture this" items. Implementation: **[TASK-130](task-130)**.
- **Automation-readiness unit**: the **Question Archetype** (TASK-113). Each carries a
  readiness class -- `deterministic` / `generatable` / `needs-human` -- assigned by Mike
  during review, with an evidence-based *suggested* default. Advisory; never auto-fills.
- **Eval-harness ground truth**: Mike's recorded accept / edit / decline verdicts. "Train
  the model" means this decision corpus + eval loop -- no literal training run (out of scope).
- **Curation gate**: capture greedily (every guided session's raw bundle). Auto-curate on
  materialization. "Tidy" is the prune step -- after curated + reviewed + grace window the
  raw bundle is deletable, and a curation report flags low-value captures (no new archetype,
  signature, or drift) as prune-first.

## Spec-lock deliverables (all done, 2026-08-29)

- [x] **[ADR 010 -- Link-to-Application Capture and the Datalake](../../docs/adr/010-link-to-application-capture-and-the-datalake.md)** --
  one document (not split; the legibility decision confirmed one ADR is fine). Covers all
  six sections: entry seam, correlation spine, datalake modality + `Bundle`/`Extractor`
  contract, ATS topology, automation-readiness loop, legibility surfaces.
- [x] **[docs/architecture/datalake.md](../../docs/architecture/datalake.md)** -- modality,
  storage layout + `manifest.json` shape, capture (write) side, `Datalake::` read contract,
  curation + prune posture.
- [x] `signature-registry.md` -- "Decided" gains the ATS-topology entry (build
  `TenantIdentity`, add the "context-gathering opportunity" finding category) and the
  `session_token`-spine note.
- [x] `application-question-knowledge-graph.md` -- new "Automation readiness" section
  (`archetype_readiness_assessments` + value-free `answer_proposal_verdicts` + eval harness
  + hard guardrail).
- [x] `panoramic-view.md` -- "View full trace" resolves to `guided_sessions#show` for guided
  runs.
- [x] `CONTEXT.md` glossary -- **Harness**, **Processed Through the Harness**, **Correlation
  Spine**, **Datalake**, **Datalake Bundle**, **Readiness Class**.
- [x] `.gitignore` -- `data/datalake/`.
- [x] Implementation tasks: **[TASK-126](task-126)** (raw capture), **[TASK-127](task-127)**
  (readiness corpus/eval), **[TASK-128](task-128)** (legibility surfaces),
  **[TASK-129](task-129)** (entry seam + correlation spine), **[TASK-130](task-130)**
  (ATS topology). TASK-128 depends on TASK-129.

## Not yet specified

*(nothing -- the map is closed. Remaining unknowns are implementation details owned by the
tasks above: the concrete `manifest.json` schema, prune grace-window durations, the
readiness suggested-default formula, the `datalake_extractor_version` re-extract mechanics.)*

## Out of scope

- **Literal local-model training / fine-tuning / embedding jobs** on the corpus. The corpus
  is designed to stay exportable, but a training run is a fresh effort.
- **Re-planning TASK-112 / TASK-113 / Panoramic View.** They are dependencies at current
  scope.
- **Building the datalake store, extractors, or read models.** The map specs the boundary
  and policy; construction is post-spec backlog work (raw-capture side is TASK-126,
  readiness side is TASK-127).
- **Encryption-at-rest or redaction of the raw layer.** Considered and rejected for v1
  (machine-local + aggressive prune is the chosen posture); revisit only if the retention
  posture changes.
- **Closed-shadow-DOM capture in the extension** (TASK-121). Needs a `document_start`
  MAIN-world `attachShadow` shim; a separate small task only if a target ATS is shown to put
  application fields inside closed roots.
- **Any auto-fill / auto-submit switch driven by readiness class or eval score** (TASK-124).
  Bounded Agency: the readiness loop only ever changes whether a proposal is offered without
  a review prompt, never whether an answer is entered or sent.
- **Automation-readiness rollups on the legibility surfaces** (TASK-125). Deferred from
  `job_postings/show` and `companies/show`; readiness UI is TASK-127's, in archetype review.
