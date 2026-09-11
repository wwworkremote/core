---
id: TASK-136
title: 'Datalake read contract: Datalake::Bundle + Datalake::Extractor'
status: Done
assignee: []
created_date: '2026-08-30 22:11'
updated_date: '2026-08-30 22:11'
labels:
  - application-capture-datalake
  - 'wayfinder-map:doc-7'
dependencies: []
references:
  - app/services/datalake/bundle.rb
  - app/services/datalake/extractor.rb
  - docs/adr/010-link-to-application-capture-and-the-datalake.md
  - >-
    backlog/tasks/task-123 -
    Wayfinder-decision-datalake-to-operational-read-model-contract.md
type: feature
ordinal: 152000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implementation of the TASK-123 read contract (ADR 010). The last doc-7 read-side piece: the seam operational consumers (question graph, trace evidence, topology findings) use to read raw guided-session assets instead of File.read on the path.

Contract (from TASK-123, not re-litigated): thin Datalake:: namespace — Datalake::Bundle (read-only manifest + asset bytes for one session_token) and Datalake::Extractor (base: key / version / extract(bundle)). Consumers persist derived data in their own tables stamped with datalake_extractor_version; a mismatch triggers re-extraction. Cheap value-free derivation stays inline on complete!; expensive extractors enqueue on first read with a "still extracting" view state.

Scope of THIS task: build the contract surface. The enqueue-on-read machinery + the first concrete extractor land with their first consumer (a question-graph DOM extractor).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Datalake::Bundle: present?, pruned? (from the prune ledger), assets(type:, event_id:), gaps, read(seq) returning sha256-verified bytes and raising on a manifest/file mismatch
- [x] #2 GuidedSession#datalake_bundle accessor returns a Datalake::Bundle
- [x] #3 Datalake::Extractor base class: subclass declares version + implements extract(bundle); .call(bundle) runs it; .stale?(stamped_version) drives re-extraction; key defaults to demodulized underscore
- [x] #4 Focused specs for Bundle (each method, tamper detection, pruned vs never-captured) and Extractor (version required, call, stale?, key)
- [x] #5 datalake.md Read section updated to reflect the built seam; rubocop + brakeman clean
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Merged to main (`880d0ca7`, branch `task-datalake-read-side`). Datalake + guided_session specs 31/0; full suite running; rubocop + brakeman clean. No schema change.

**`Datalake::Bundle`** (`GuidedSession#datalake_bundle`, `Datalake::Bundle.for(token)`) — the read-only view of one guided session's raw bundle:
- `present?` — a bundle was captured
- `pruned?` — reads `data/datalake/pruned.json` (added `Datalake::Prune.pruned?`), so a consumer tells "pruned" from "never captured"
- `assets(type:, event_id:)` → `Bundle::Asset` structs (`seq`, `type`, `event_id`, `sha256`, `bytes`, `captured_at`)
- `gaps` → manifest gap entries
- `read(seq)` → asset bytes, **sha256-verified against the manifest**, raises `Datalake::Bundle::Error` on an unknown seq or a file/manifest mismatch (a corrupt or tampered bundle fails loudly, never feeds a silent extraction)

**`Datalake::Extractor`** — base class. A subclass declares `version` (bump only when identical raw material would yield materially different output — ADR 009 `comparison_rules_version` discipline), implements `extract`, reads bytes only through the injected `Bundle`. `Extractor.call(bundle)` runs it; `Extractor.stale?(stamped_version)` drives re-extraction against a consumer's own `datalake_extractor_version` column; `key` defaults to the demodulized underscored class name.

**Deliberately not built (YAGNI — no consumer yet):** the enqueue-on-first-read job + "still extracting" view state, and any concrete `Datalake::Extractors::*`. These land with the first consumer, expected to be a question-graph DOM occurrence extractor (`QuestionOccurrences::Record` today works off event evidence; it reaches into the DOM bundle only when that's insufficient).

**Specs** — `spec/services/datalake/bundle_spec.rb` (7): present?, type/event filtering, verified read, unknown-seq raise, tamper detection, gaps, pruned-vs-never. `spec/services/datalake/extractor_spec.rb` (4): version required, `.call` runs `extract`, `stale?`, `key` default.

**Also recovered** the `datalake:prune` rake task, which fell out of the index in the TASK-135 commit (`09c7d3c9`) due to an overcommit stash/retry race after the RubyLLM flake failed the first pre-commit run. `Datalake::Prune` + spec had landed; the task wrapper had not. TASK-135 AC#2 is now genuinely satisfied on main.

doc-7's datalake arc is complete bar the first concrete extractor.
<!-- SECTION:FINAL_SUMMARY:END -->
