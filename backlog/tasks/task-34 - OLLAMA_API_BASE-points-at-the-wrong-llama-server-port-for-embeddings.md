---
id: TASK-34
title: OLLAMA_API_BASE points at the wrong llama-server port for embeddings
status: Done
assignee: []
created_date: '2026-08-10 12:23'
updated_date: '2026-08-15 18:46'
labels: []
dependencies: []
references:
  - .env
  - packages/ingestion/app/services/job_boards/embedder.rb
  - bin/smoke
  - bin/verify_llm.rb
priority: medium
type: bug
ordinal: 39000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Discovered 2026-08-10 while running `bin/smoke` as part of a full-system regression-test validation pass.

`.env` sets `OLLAMA_API_BASE=http://localhost:11500/v1`, and `JobBoards::Embedder::API_URL` (packages/ingestion/app/services/job_boards/embedder.rb) builds its embeddings endpoint from that base. But two separate `llama-server` processes run locally:
- port 11500: chat/completion model, alias "local", started WITHOUT `--embeddings`
- port 11501: `nomic-embed-text-v2-moe` model, started WITH `--embeddings --pooling mean`

So any live (non-stubbed) call to `JobBoards::Embedder.embed_text`/`.post_embedding` hits the wrong server -- one that isn't configured to serve embeddings at all. `bin/smoke`'s LLM check confirms this: `4. Embeddings (/v1/embeddings) ... FAIL -- server not started with --embeddings flag`.

This doesn't show up in the RSpec suite because `spec/rails_helper.rb` globally stubs `VectorIntelligence.embed`/`JobBoards::Embedder.embed_text` for every spec -- so the suite is green while the underlying live path is broken. It also doesn't affect `JobPostingTrendRollup` or `RoleFamily`-based work from the task-32 milestone (those don't call the embedder), but it does mean any live semantic-search, hybrid_search's vector leg, or embedding-generation job (`JobBoards::AnalysisJob`, `Resume::EmbeddingJob`) currently produces no real embeddings in this dev environment when actually exercised outside of tests.

`bin/smoke`'s inference check also failed separately (`3. Inference (/v1/chat/completions) ... FAIL (timeout after 90s)`) -- noting it here since it was found in the same pass, but it's a distinct issue (possibly related to task-33's RubyLLM::ModelNotFoundError, possibly just a slow/overloaded local model) and may need its own investigation rather than being bundled into this fix.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 OLLAMA_API_BASE (or a separate, more specific env var if embeddings and chat should stay independently configurable) points JobBoards::Embedder at a server actually started with --embeddings
- [ ] #2 bin/smoke's embeddings check passes
- [ ] #3 A live (non-stubbed) call to JobBoards::Embedder.embed_text returns a real embedding vector in this dev environment
- [ ] #4 Investigated whether the bin/smoke inference timeout (port 11500, 90s timeout) is related to or independent of this fix, and noted the finding (even if the timeout itself isn't resolved here)
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Superseded by TASK-38's resolution, not fixed as originally scoped. TASK-38 (2026-08-15) migrated the pgvector schema from 3584 to 768 dims to match the actually-running embed model (nomic-embed-text-v2-moe on port 11501) and applied the app-side OLLAMA_EMBED_API_BASE routing fix this task also called for. A live, non-stubbed JobBoards::Embedder.embed_text call now returns a real 768-dim embedding in this dev environment -- verified as part of TASK-38's backfill (job_postings coverage 37.7% -> 98.6%). Closing as resolved via TASK-38 rather than duplicating that work here.
<!-- SECTION:FINAL_SUMMARY:END -->
