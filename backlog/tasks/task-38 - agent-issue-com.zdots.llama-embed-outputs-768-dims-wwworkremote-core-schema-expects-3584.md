---
id: TASK-38
title: >-
  [agent-issue] com.zdots.llama-embed outputs 768 dims, wwworkremote/core schema
  expects 3584
status: Done
assignee: []
created_date: '2026-08-14 01:40'
updated_date: '2026-08-15 15:05'
labels:
  - agent-reported
  - request
dependencies: []
modified_files:
  - db/migrate/20260815023000_migrate_embeddings_to_768_dimensions.rb
  - db/schema.rb
  - packages/ingestion/app/services/job_boards/embedder.rb
  - app/services/resume/profile_embedder.rb
  - app/controllers/job_postings_controller.rb
  - docs/architecture.md
priority: medium
ordinal: 43000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**Type:** request
**Severity:** medium
**Trace ID:** `50984bfa33d1014b19270b1a75ae0360`

wwworkremote/core (Rails app) has 5 pgvector columns (job_postings, career_profiles, resumes, skills, system_insights) fixed at vector(3584) with matching HNSW indexes, and 1770 JobPosting rows already hold real 3584-dim embeddings saved previously. The currently-running com.zdots.llama-embed launchd service (port 11501, nomic-embed-text-v2-moe.Q8_0.gguf, --embeddings --pooling mean) returns 768-dim vectors -- confirmed live via curl to /v1/embeddings. This is a hard mismatch: pointing the app's embedder at port 11501 (the only embeddings-capable local server right now; the chat model on port 11500 runs without --embeddings) produces ActiveRecord::RecordInvalid ('Embedding must have 3584 dimensions') on every save instead of a working embedding. Requesting either: (a) com.zdots.llama-embed swapped to a model that outputs 3584 dims (matching whatever originally populated those 1770 rows), or (b) confirmation of the intended target embedding dimension going forward so the app-side schema can be migrated to match. Not modifying the zdots-managed llama-server config myself per policy -- app-side URL routing fix (OLLAMA_API_BASE for chat vs new OLLAMA_EMBED_API_BASE for embeddings) already applied in the Rails app since that half was a real app-side bug regardless of this dimension issue.

---
*Filed via `zdots-issue`. Operator review required before any changes are made.*
*Do not modify zdots to work around this issue — wait for operator resolution.*
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Resolved by migrating the schema to match the currently-running embed model rather than swapping the model back (nomic-embed-text-v2-moe is purpose-built for embeddings; the old 3584 dims came from pooling Qwen2.5-7B hidden states, not a dedicated embedding model).

- Migration 20260815023000: all 5 pgvector columns (job_postings, career_profiles, resumes, skills, system_insights) 3584 -> 768 dims, HNSW indexes rebuilt at the new width.
- Found and fixed a second, unrelated bug the migration's table rewrite exposed: index_job_postings_on_signature was silently invalid (indisvalid: false), letting 134 duplicate postings across 67 signatures slip past the "unique" constraint. Deduped (kept oldest per signature; verified none had pipeline/contact/lead history) and rebuilt the index.
- Found and fixed a second dimension-adjacent bug: JobBoards::Embedder and Resume::ProfileEmbedder truncated source text at character budgets tuned for the old model's 32K context; the new model's 512-token context made most calls fail with exceed_context_size_error (60% failure rate on first backfill attempt). Fixed by truncating the fully-assembled text instead of per-field.
- Backfilled all 5 tables against the corrected truncation. job_postings embedding coverage: 37.7% -> 98.6% (4518/4584, up from 1770/4712 pre-dedup).
- Wired the already-built, already-tested JobPosting.hybrid_search (BM25 + vector RRF, TASK-32.1) into the actual job postings search UI, which had only ever used plain keyword search.

603+ specs green, RuboCop clean, all commits through the full pre-commit hook chain.
<!-- SECTION:FINAL_SUMMARY:END -->
