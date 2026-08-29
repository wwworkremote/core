# The Datalake: Raw Guided-Session Assets, Schema-on-Read

**Status: spec-locked, not yet built.** Charted as
[wayfinder map doc-7](../../backlog/docs/wayfinder/doc-7%20-%20Wayfinder-map-link-to-application-capture-and-the-datalake.md);
the decision record is [ADR 010](../adr/010-link-to-application-capture-and-the-datalake.md).
Implementation: TASK-126 (capture), TASK-127 (readiness corpus), TASK-128 (legibility).

## What "datalake" means here

A **modality, not a product and not a database.** A guided session produces
heterogeneous raw material — DOM snapshots, HAR logs with response bodies, full-page
screenshots — that is worth keeping but not worth forcing into a schema at write time,
because what we will want to extract from it changes as the system learns an ATS's shape.

So: land it raw and tidy, keyed by one identifier, described by a manifest; extract
structure **on read**, into each consumer's own tables, versioned so a better extractor
re-runs itself.

The word is deliberately lower-case. There is no `Datalake` model, no lake service, no
ingestion pipeline. There is a directory convention and a thin read wrapper.

## The correlation spine

`GuidedSession#session_token` is the run super-identifier for a guided lap (ADR 010 §2).
During a guided session the extension stamps it onto the four `trace_id`-scoped capture
tables and onto the materialized `Scenario`. Everything about one supervised application
— the timeline events, the value-free structure, the raw bundle, the comparison — hangs
off that one token.

`application_trace_id` and `Scenario#scenario_token` are unchanged and still mean what
they meant for non-guided paths. There is no backfill.

## Storage layout

```
data/datalake/                      # git-ignored, machine-local, never synced
  sessions/
    <session_token>/
      manifest.json
      0001-intake.dom.html
      0001-intake.screenshot.png
      0002-resolution.dom.html
      0002-resolution.har.json
      0002-resolution.screenshot.png
      ...
  corpus/
    <archetype-id>.jsonl            # automation-readiness corpus (TASK-127)
```

- **One directory per `session_token`.** Plain files. No nesting beyond this.
- **`manifest.json` is authoritative** and owned by Rails (the extension never writes it
  directly). It enumerates every asset:

  ```json
  {
    "session_token": "…",
    "purpose": "application_execution",
    "assets": [
      { "seq": 1, "step": "intake", "guided_session_event_id": 41,
        "type": "dom", "path": "0001-intake.dom.html",
        "sha256": "…", "bytes": 20481, "captured_at": "2026-08-29T20:00:01Z" }
    ],
    "gaps": [
      { "seq": 2, "step": "resolution", "type": "har",
        "reason": "debugger_detached_by_user", "at": "2026-08-29T20:01:12Z" }
    ]
  }
  ```

- **New asset types are new manifest entries.** No migration, no enum, no schema bump.
- **Gaps are recorded, not hidden.** A cross-origin frame, a closed shadow root, a
  post-`onDetach` transition — each is a `gaps[]` entry so a reader knows the absence is
  known, not an oversight (the same discipline as Panoramic View's `noop_trace`).

## Capture (write side) — TASK-126

- **Trigger**: one capture per emitted `GuidedSessionEvent`. The recorder already judges
  which transitions are meaningful (TASK-112); the datalake piggybacks on that judgement,
  staying 1:1 with the timeline.
- **Transport**: the extension POSTs one asset at a time to
  `POST /api/v0/guided_sessions/:session_token/datalake_assets` — mirrors the existing
  events endpoint, `Rails.env.local?` gate, routed through the `API_FETCH` background
  relay. Rails writes the file under the session directory and updates `manifest.json`.
  PII bytes transit the localhost Rails process; they are written to disk, never logged
  or stored in the database. The File System Access API and a native messaging host were
  both considered and judged not worth it.
- **Fidelity by purpose** (Chrome MV3 capabilities, TASK-121):
  | | `application_research` | `application_execution` |
  |---|---|---|
  | DOM | content-script `Element.getHTML` (open shadow roots + same-origin frames) | same |
  | Network | — | full HAR incl. response bodies, via `chrome.debugger` + CDP |
  | Screenshot | `captureVisibleTab` (viewport) | full-page, via CDP `Page.captureScreenshot` |
  | Banner | none | per-tab "started debugging this browser" banner |

  `chrome.debugger` yields when DevTools opens on the tab (`onDetach`); the session
  degrades to the light path and records the gap. Mike can override the per-purpose
  default. The extension needs **no new permissions**.
- **Failure is never fatal**: a capture error emits an `EXTENSION_ERROR` event and a
  `gaps[]` entry; the guided session continues.

## Read (extract side) — the `Datalake::` contract, TASK-123

```
Datalake::Bundle          # manifest + asset bytes for one session_token, READ-ONLY
Datalake::Extractor       # base: key / version / extract(bundle)
  Datalake::Extractors::…  # one subclass per consumer
```

- **Consumers read raw assets only through `Datalake::Bundle`** — never `File.read` on
  the path. `Bundle` is the seam that lets the storage layout change later without
  touching consumers.
- **No shared cache table.** Each consumer (`Applications::TraceEvidence`, the question
  graph, the readiness corpus builder) persists what it derives into **its own domain
  tables**, each row stamped with a `datalake_extractor_version`. On read, a version
  mismatch triggers re-extraction — identical to `Scenarios::ComparisonRules::VERSION`
  discipline in [ADR 009](../adr/009-reference-comparison-drift-and-coverage.md).
- **Cadence is hybrid**:
  - *Cheap, structural, value-free* derivation stays **inline** on
    `GuidedSession#complete!` — this is `Scenarios::GuidedCapture` today, which reads
    event evidence and never touches raw assets.
  - *Expensive* extractors (parsing a HAR, diffing DOM) are **enqueued on first read**;
    the view shows a "still extracting" state until the job lands.
- **The lake never pushes.** Operational models pull. `Datalake::` covers guided raw
  bundles only — the four `trace_id`-scoped capture tables stay as-is and are consumed
  directly. A read model consumes `{bundle when present} + {capture tables always}`.

## Curation and prune

Capture is greedy — every guided session's raw bundle is kept. "Tidy and selective" is
the **prune** step, not a capture filter:

1. On materialization, cheap structural extraction auto-curates (value-free markers into
   `Scenario` signatures, as today).
2. After a bundle is curated **and** reviewed **and** a short grace window has passed, it
   is **prune-eligible** — it can be deleted, because the raw layer is the PII-bearing
   one and the value has already been extracted.
3. A **curation report** flags bundles that produced no new archetype, signature, or
   drift finding as *prune-first*.

The prune job itself and the curation report are TASK-126-out-of-scope follow-ups; the
policy is fixed here.

## What this is not

- Not encrypted at rest, not redacted — machine-local + aggressive prune is the chosen
  posture. Revisit only if the retention posture changes.
- Not a training set. The `corpus/` directory is designed to stay exportable, but a
  literal training / fine-tuning / embedding run is a separate effort (ADR 010,
  "Out of scope").
- Not synced, committed, or uploaded — ever. `data/datalake/` is git-ignored and stays
  on the one machine.
