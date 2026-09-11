# ADR 010: Link-to-Application Capture and the Datalake

## Status
Accepted

Charted as [wayfinder map doc-7](../../backlog/docs/wayfinder/doc-7%20-%20Wayfinder-map-link-to-application-capture-and-the-datalake.md)
across four grilling rounds (2026-08-29). This ADR is the spec-locked result. Every
decision below links the child ticket that holds its full reasoning.

## Context

Two halves of a system exist and have never been joined into one continuous path:

- **Ingestion** — a `JobPosting` arrives, becomes a `UserJobPosting` when Mike engages
  it, and moves through an AASM pipeline (`favorite` → `apply` → `interview` → …).
- **Guided capture** — a `GuidedSession` records a supervised lap through an employer's
  application flow ([ADR 005](005-supervised-intent-capture.md),
  [ADR 006](006-bpmn-lite-guided-session-validation.md)), materializes into a `Scenario`
  ([ADR 009](009-reference-comparison-drift-and-coverage.md)), and is compared against a
  per-provider Reference Scenario.

Nothing links a `JobPosting` to a `GuidedSession`. Starting a supervised application from
a posting is a copy-paste-the-URL manual step; the recording that results is not
associated back to the posting, the company, or the campaign. Separately, the guided
recorder keeps only *value-free structural evidence* — it never retains the DOM, the
network traffic, or screenshots, so there is no raw material to learn an ATS's topology
from, and no way to answer "what did this page actually look like when I applied."

Mike's stated intent: start from one job-posting link, have the harness record the
posting session and then the application, capturing his steps to build a decision corpus
for adapting the system toward automation; nurture the local question/answer mapping;
map what each company and each hiring system asks; and retain the recorded assets
(DOM, HAR, screenshots) *and* the extracted Q&A in a **datalake modality** — a tidy,
schema-on-read landing zone that context extracts cleanly out of into the operational
system. "A little greedy but tidy and selective about curating the collection."

**Standing constraints** (from [CONTEXT.md](../../CONTEXT.md), unchanged):

- **Bounded Agency** — nothing here authorizes, fills, or submits an application. Every
  surface is advisory or read-only.
- **Intent Is First-Class** — the capture preserves why, not just what.
- The raw datalake layer is **machine-local, git-ignored, never synced or committed**. It
  is Mike's own job-search data — not PHI, but PII-bearing.

Out of scope for this ADR (see the map's "Out of scope"): literal local-model
training/fine-tuning on the corpus; re-planning TASK-112 / TASK-113 / Panoramic View;
building the datalake store, extractors, or read models; encryption-at-rest or redaction
of the raw layer; closed-shadow-DOM capture; any auto-fill / auto-submit switch.

## Decision

### 1. Entry seam — `JobPosting` → `GuidedSession`

*(map decision, resolved inline while charting; implementation is TASK-129.)*

- `GuidedSession belongs_to :user_job_posting`, **nullable** — a verification-only or
  ad-hoc session still has none, exactly as `Scenario#user_job_posting_id` is nullable.
- A **"Start supervised application"** affordance on `job_postings/show` creates a
  `UserJobPosting` if none exists, then a `GuidedSession` linked to it.
- Starting or completing a session **never** auto-changes `UserJobPosting` AASM state.
  Completion may **propose** a transition as a `HumanTask`
  ([human-task-pipeline](../architecture/human-task-pipeline.md)) — same advisory
  discipline as Reference Comparison in ADR 009.

### 2. Correlation spine — promote `GuidedSession#session_token`

*(map decision, resolved inline.)*

`GuidedSession#session_token` (already `has_secure_token`, already carried by the
extension as `?guided_session_token=`) becomes the **run super-identifier** for a guided
lap. During a guided session the extension stamps that token onto:

- the four `trace_id`-scoped capture-table rows it writes
  (`application_field_observations`, `application_field_mappings`,
  `application_field_answers`, `extension_error_events`), and
- the materialized `Scenario`.

`application_trace_id` and `Scenario#scenario_token` keep their existing meanings for
non-guided paths — this is an addition, not a migration. There is **no backfill** of
`session_token` onto historical capture rows. This resolves the propagation gap
[panoramic-view.md](../architecture/panoramic-view.md) and
[signature-registry.md](../architecture/signature-registry.md) both name: for a *guided*
run, one identifier now holds the whole coordinated run together.

### 3. Datalake — a modality, not a product

*(full contract: [Datalake ↔ operational read-model contract](../../backlog/tasks/task-123%20-%20Wayfinder-decision-datalake-operational-read-model-contract.md);
Chrome capture capabilities: [Chrome MV3 capture capabilities](../../backlog/tasks/task-121%20-%20Wayfinder-research-Chrome-MV3-capture-capabilities-for-the-raw-datalake-layer.md);
recorder seam: [Guided-recorder raw-capture seam](../../backlog/tasks/task-122%20-%20Wayfinder-decision-guided-recorder-raw-capture-seam-for-the-datalake.md).
Narrative: [docs/architecture/datalake.md](../architecture/datalake.md).)*

The datalake is a **schema-on-read landing zone** for the heterogeneous raw assets of a
guided session, plus the value-free structure already captured. It is **not** a new
database and **not** a product name.

- **Storage layout** — one directory per `session_token` under a git-ignored repo path
  (`data/datalake/sessions/<session_token>/`), with a `manifest.json` enumerating every
  asset (`type`, step/transition, `sha256`, `captured_at`, `bytes`, and explicit gap
  entries) and the assets alongside as plain files. New asset types are new manifest
  entries — no migration.
- **Transport** — the extension POSTs one asset at a time to a new
  `POST /api/v0/guided_sessions/:session_token/datalake_assets` endpoint (mirrors the
  events endpoint, `Rails.env.local?` gate, `API_FETCH` relay). Rails writes the file and
  owns `manifest.json`. One capture per emitted `GuidedSessionEvent` — 1:1 with the
  timeline, piggybacking on TASK-112's transition judgement.
- **Fidelity by purpose** — `application_execution` attaches `chrome.debugger` + CDP for
  full HAR bodies and full-page screenshots (carries a per-tab banner, yields when
  DevTools opens); `application_research` stays light (content-script DOM +
  `captureVisibleTab`, no banner). Mike can override. Capture failures emit an
  `EXTENSION_ERROR` event + a manifest gap entry and **never** break the session.
- **Read contract** — a thin `Datalake::` namespace:
  - `Datalake::Bundle` — manifest + asset bytes for one `session_token`, **read-only**.
    Every consumer reads raw assets **through `Bundle`, never `File.read` on the path**.
  - `Datalake::Extractor` — base class with `key` / `version` / `extract(bundle)`. One
    subclass per consumer.
  - **No shared cache table.** Each consumer persists derived data into its **own domain
    tables**, stamped with a `datalake_extractor_version`. A version mismatch on read
    triggers re-extraction — the same discipline as
    `Scenarios::ComparisonRules::VERSION` in ADR 009.
  - **Cadence is hybrid** — cheap structural derivation stays inline on
    `GuidedSession#complete!` (`Scenarios::GuidedCapture`, value-free, never touches raw
    assets). Expensive extractors are enqueued on first read; the view shows a "still
    extracting" state.
  - `Datalake::` covers **guided raw bundles only**. The four `trace_id`-scoped capture
    tables stay as-is and are consumed directly. A read model consumes
    `{bundle when present} + {capture tables always}`.
- **Raw-layer protection** — unencrypted on the local filesystem, git-ignored, never
  synced / committed / uploaded. A documented boundary, not a mechanism. The raw bundle
  gets a short grace window after it is curated and reviewed, then becomes
  **prune-eligible** — precisely because it is the PII-bearing layer. A curation report
  flags low-value bundles (no new archetype, signature, or drift) as prune-first.
- **Dropped for v1** (TASK-121): closed-shadow-DOM capture, a content-script resource
  inliner, `<all_urls>`, `webRequest`. The extension needs **no new permissions** — it
  already holds `activeTab`, `debugger`, and the named host list.

### 4. ATS topology — extend the Signature Registry

*(map decision, resolved inline; implementation is TASK-130.)*

"Map the topology of a system I can't change, and identify opportunities to gather more
context" is served by extending [signature-registry.md](../architecture/signature-registry.md),
not a new subsystem:

- `HandshakeCheck::SIGNATURE_EXPECTATIONS` (per-provider) + the **now-built**
  `TenantIdentity` (per-employer instance — `provider`, tenant identifier, `created_at`;
  never credentials) + the per-provider Reference Scenario **together are the topology**.
- **New finding category: "context-gathering opportunity."** `optional-and-missing`
  signatures and un-mapped observed fields surface on `HandshakeCheck` / comparison
  output as ranked, reviewable **"could capture this"** items — the greedy-but-curated
  loop, made legible instead of implicit.

### 5. Automation-readiness — a decision corpus and an eval harness

*(full contract: [Automation-readiness corpus and eval-harness shape](../../backlog/tasks/task-124%20-%20Wayfinder-decision-automation-readiness-corpus-and-eval-harness-shape.md);
implementation is TASK-127.)*

"Train the AI model" means **building a decision corpus and an evaluation loop** — there
is no literal training run.

- **Unit of readiness: the Question Archetype** (TASK-113). Each carries a readiness
  class — `deterministic` / `generatable` / `needs-human` — in an **append-only
  `archetype_readiness_assessments` table** (FindingDisposition-style: latest applicable
  wins, a merge/split carries the prior assessment forward as a *suggestion*). Mike
  assigns it during archetype review, with an evidence-based **suggested default**
  (inputs: occurrence frequency, historically-winning strategy source, median edit
  distance, sample-size floor).
- **Verdicts: a value-free `answer_proposal_verdicts` table** — sha256 hashes +
  `edit_distance` + `strategy_source` (`canned` / `template` / `ai`) + `verdict`
  (`accepted` / `edited` / `declined`). One row per proposal shown, declines included.
  **No answer text.** Captured in the sidepanel answer-proposal flow (TASK-78).
- **The harness replays the real path** — `LLM::AnswerGenerator.call` (`CannedAnswers` +
  `ApplicationAnswerTemplate` + `PromptBuilder` / prompt constants + the configured
  `answer_generation` model) and reports **verbatim-acceptance rate + median edit
  distance, split by strategy**. Corpus = per-archetype JSONL under `data/datalake/corpus/`
  (git-ignored). `rake automation_readiness:corpus` + `automation_readiness:eval`.
- **Advisory only.** A hard guardrail: nothing the readiness loop produces flips an
  archetype to auto-fill or auto-submit. It only ever changes whether a proposal is
  offered *without* a review prompt — never whether an answer is entered or sent.

### 6. Harness-legibility surfaces

*(full contract: [Wayfinder decision: wwworkremote.localhost harness-legibility surfaces](../../backlog/tasks/task-125%20-%20Wayfinder-decision-wwworkremote.localhost-harness-legibility-surfaces.md);
implementation is TASK-128.)*

- **Per-posting** (`job_postings/show`): a small state badge with the existing title
  badges, plus the "Start supervised application" affordance grown into an aside card.
  Furthest state reached — `in_progress` / `recorded` / `compared` — derived from the
  `GuidedSession`s linked to the posting's `UserJobPosting`. No new column.
- **Per-company** (`companies/show`): a stat block ("N supervised applications · M
  recorded sessions") + the same badge on each posting row. **"Processed through the
  harness" is defined once** — a `UserJobPosting` with ≥ 1 `GuidedSession` at
  `status = completed` — and reused everywhere it appears.
- **Navigation**: contextual entry via the aside card + a `GET /guided_sessions` index
  **linked from the Admin/Tools menu, not primary nav**. `guided_sessions#show` is the
  **single canonical per-run view**; Panoramic View's planned "View full trace" link
  resolves there for guided runs. Session views back-link to posting + company.
- Automation-readiness rollups are **deferred** off these surfaces — readiness UI lives
  in archetype review (TASK-127).

## Consequences

- **New association**: `GuidedSession#user_job_posting_id` (nullable).
- **New endpoint**: `POST /api/v0/guided_sessions/:session_token/datalake_assets`
  (`Rails.env.local?` only). **New route**: `GET /guided_sessions` (index).
- **New namespace**: `Datalake::Bundle`, `Datalake::Extractor`. **New git-ignored path**:
  `data/datalake/` (sessions + corpus).
- **New tables**: `tenant_identities`, `archetype_readiness_assessments`,
  `answer_proposal_verdicts`. **New finding category** on `HandshakeCheck` output.
- **Extension**: gains a datalake-asset POST path and, for `application_execution`, a
  `chrome.debugger` attach for HAR bodies + full-page screenshots. No new permissions,
  no new install warning. `manifest.json` version bump on the change.
- The four `trace_id`-scoped capture tables, `Scenario` / `ScenarioSignature`,
  `ReferenceComparison` / `ComparisonFinding` / `FindingDisposition`, and the Panoramic
  View design are **unchanged** — this ADR is connective tissue plus the datalake, not a
  redesign of any of them.
- **Implementation tickets**: TASK-126 (raw capture), TASK-127 (readiness), TASK-128
  (legibility surfaces), TASK-129 (entry seam), TASK-130 (ATS topology). Sequencing is
  ordinary backlog work; TASK-128 depends on TASK-129.
- **Threshold — a real datalake store**: `Datalake::Bundle` is plain-file + manifest on
  purpose. Move to an object store or a metadata table only when multi-machine access or
  bundle volume makes the flat layout hurt — not before.
- **Threshold — `session_token` on non-guided paths**: the spine is guided-only. Promote
  it further only if a non-guided capture needs the same coordinated-run identity.

## Rejected Alternatives

- **A new orchestrator (Camunda-style) for the link-to-application path** — rejected the
  same way ADR 009 rejected it: `UserJobPosting`'s AASM is the one orchestrated
  authority; the harness is a recorder and a narrator, never a second state machine.
- **Auto-advancing `UserJobPosting` state on session completion** — violates Bounded
  Agency. Completion *proposes* a transition as a `HumanTask`.
- **A shared datalake cache table read by every consumer** — couples the consumers and
  duplicates the version-stamp problem. Each consumer owns its derived tables; `Bundle` /
  `Extractor` is the only shared surface.
- **`session_token` backfill onto historical capture rows** — the spine is a
  going-forward guarantee for guided runs; retrofitting it onto rows written before the
  seam existed buys nothing.
- **Retaining raw bundles indefinitely** — this is the PII-bearing layer. Greedy capture,
  then curate-and-prune. Encryption-at-rest was considered and rejected for v1 in favour
  of machine-local + aggressive prune.
- **A literal training/fine-tuning run on the corpus** — a fresh effort. The corpus is
  designed to stay exportable; this ADR builds the decision corpus and the eval loop, not
  a model.
- **A dedicated "Harness" primary-nav section** — the app is a power-user tool for one
  operator; the subsystem is reached contextually from a posting, with an index tucked
  under Admin/Tools. `guided_sessions#show` is the one run view, not a new page family.
- **Automation-readiness rollups on `job_postings/show` / `companies/show`** — deferred.
  Those surfaces answer "did this go through the harness"; readiness is an archetype-review
  concern.
