---
id: TASK-38
title: >-
  [agent-issue] com.zdots.llama-embed outputs 768 dims, wwworkremote/core schema
  expects 3584
status: To Do
assignee: []
created_date: '2026-08-14 01:40'
labels:
  - agent-reported
  - request
dependencies: []
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
