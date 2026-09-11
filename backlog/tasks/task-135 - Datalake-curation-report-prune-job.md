---
id: TASK-135
title: Datalake curation report + prune job
status: Done
assignee: []
created_date: '2026-08-30 22:01'
updated_date: '2026-08-30 22:01'
labels:
  - application-capture-datalake
  - 'wayfinder-map:doc-7'
dependencies: []
references:
  - app/services/datalake/prune.rb
  - lib/tasks/datalake.rake
  - docs/adr/010-link-to-application-capture-and-the-datalake.md
  - docs/architecture/datalake.md
type: feature
ordinal: 151000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The "Curation and prune" step from ADR 010 / docs/architecture/datalake.md. Capture is greedy; prune is the selective step that deletes the PII-bearing raw layer once value has been extracted and a grace window has passed. A TASK-126-out-of-scope follow-up, now built.

Policy (fixed in ADR 010): a bundle is prune-eligible once its GuidedSession is curated (materialized into a Scenario) AND reviewed AND a short grace window has passed. A curation report flags bundles that produced no new archetype/signature/drift finding as prune-first. "Reviewed" is satisfied at prune time -- the job is a dry run that prints the report; a human reads it and chooses to run the delete. No schedule.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Datalake::Prune classifies every bundle dir: keep / prune_eligible / prune_first / orphan, from GuidedSession completed + scenario_id (curated) + a 7-day grace window
- [x] #2 rake datalake:prune is a dry run that prints the report grouped by verdict; PRUNE=1 deletes the non-keep bundles via AssetStore#purge!
- [x] #3 Deleted bundles are recorded in a git-ignored data/datalake/pruned.json ledger
- [x] #4 Focused specs cover each verdict and prove a dry run touches no disk
- [x] #5 datalake.md Curation and prune section updated; rubocop + brakeman clean
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Merged to main (`14dd39c9`, branch `task-datalake-prune`). Datalake specs 14/0; full suite running; rubocop + brakeman clean.

**`Datalake::Prune`** walks every dir under `Datalake::AssetStore::ROOT` and classifies each:
- `keep` — no completed GuidedSession, or not curated (`scenario_id` nil), or `updated_at` within the `GRACE` window (7 days)
- `prune_eligible` — curated + grace elapsed
- `prune_first` — also had a clean latest ReferenceComparison (`outcome == "ok"`, zero `comparison_findings`) — nothing new learned, delete these first
- `orphan` — a bundle dir with no `GuidedSession` (deleted session / test leak)

**`rake datalake:prune`** — dry run, prints the report grouped by verdict with per-bundle asset count + reason and MB totals. **`PRUNE=1`** deletes the non-`keep` bundles via `Datalake::AssetStore#purge!` and appends each `{session_token, verdict, bytes, assets, pruned_at}` to `data/datalake/pruned.json` (git-ignored, same posture as `sessions/` and `corpus/`). No schedule — "reviewed" is a human reading the report and choosing to run it, which is stricter than a per-session flag + cron.

**Specs** — `spec/services/datalake/prune_spec.rb` (8): each verdict, `prune: true` deletes prunable + writes the ledger while keeping `keep` bundles, and a dry run touches no disk.

**ponytail ceiling** (noted in `datalake.md` + the service): low-value detection is just the clean-reference-match signal; "founded no new archetype / signature" can be added to `#low_value?` if the report proves noisy.

No schema change. The `Datalake::Bundle` / `Datalake::Extractor` read side (TASK-123 contract) is the remaining doc-7-adjacent piece.
<!-- SECTION:FINAL_SUMMARY:END -->
