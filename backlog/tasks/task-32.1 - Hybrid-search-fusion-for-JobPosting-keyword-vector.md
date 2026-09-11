---
id: TASK-32.1
title: Hybrid search fusion for JobPosting (keyword + vector)
status: Done
assignee:
  - claude
created_date: '2026-08-08 15:47'
updated_date: '2026-08-08 16:05'
labels: []
milestone: m-0
dependencies: []
parent_task_id: TASK-32
priority: high
type: enhancement
ordinal: 32000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Goal: JobPosting currently has two disconnected search paths that every caller must choose between instead of benefiting from both:
- `JobPosting#search` (app/models/job_posting.rb) -- pg_search keyword+trigram scope (`pg_search_scope :search, against: { title: "A", body: "B" }, using: { tsearch: {...}, trigram: {...} }`).
- `JobPosting.semantic_search` (app/models/job_posting.rb) -- pgvector cosine similarity via `VectorIntelligence.search` (app/services/vector_intelligence.rb), which delegates to `nearest_neighbors(:embedding, embedding, distance: "cosine")`.

Keyword search misses paraphrases/semantically-equivalent postings; vector search blurs past exact terms, acronyms, and rare tokens. Fusing both into a single ranked result set improves match quality for every feature that searches JobPosting, with no new infrastructure required -- this is a service-layer change over data pgvector/pg_search already produce.

This is the highest-leverage, lowest-dependency item from the 2026-08-08 capability audit: it has zero dependencies on the other subtasks under task-32 and benefits all of them, so it should land first.

Out of scope: adding fusion to any other model (Skill, CareerProfile, Resume) -- JobPosting only for this task. Changing the underlying pgvector index or pg_search config is also out of scope; this is about combining the two existing result sets, not replacing either.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A single JobPosting query method returns results ranked by a fused score combining keyword (pg_search) and vector (pgvector cosine) relevance for a given free-text query
- [x] #2 Existing JobPosting#search and JobPosting.semantic_search callers continue to work unchanged (fusion is additive, not a breaking replacement)
- [x] #3 A posting matching only on keyword terms (no close vector neighbor) and a posting matching only on vector similarity (no keyword overlap) both appear in fused results when relevant
- [x] #4 New RSpec coverage exercises the fused ranking with fixtures/stubs for both the keyword and vector paths, including the case where one path returns zero matches
- [x] #5 Full RSpec suite (root spec/ and packages/ingestion/spec/) passes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Add `JobPosting.hybrid_search(query_text, limit: 10)` implementing Reciprocal Rank Fusion (RRF, k=60 -- standard default from IR literature, no score normalization needed) over the two existing result orderings:
- `search(query_text)` (pg_search, already rank-ordered) -- pull `limit * 3` candidate IDs.
- `semantic_search(query_text, limit: limit * 3)` (pgvector cosine via VectorIntelligence, already distance-ordered) -- same pool size.

Fuse via `score[id] += 1.0 / (k + rank_position)` per list, sort desc, take `limit`, materialize with `where(id: ranked_ids).in_order_of(:id, ranked_ids)` (Rails 8.1 relation method, avoids a manual Ruby re-sort of AR objects). Guard blank query_text -> `none`. Fusion helper is a private class method, not part of the public surface.

Verified before writing code:
- `neighbor` gem's `nearest_neighbors` already excludes NULL-embedding rows automatically (`where.not(attribute_name => nil)`), so no manual guard needed there.
- `spec/rails_helper.rb` globally stubs `VectorIntelligence.embed` to an all-zero vector for every spec by default -- must override locally in this task's spec (same pattern as `spec/services/resume/semantic_match_finder_spec.rb`: set a specific embedding array directly on a fixture record, stub `VectorIntelligence.embed`/`JobBoards::Embedder.embed_text` to return that same array) rather than relying on the zero-vector default, since cosine distance against an all-zero query vector is degenerate.
- No existing spec exercises `JobPosting.semantic_search` at all yet -- this task's spec is the first, so it also incidentally covers that path.

Tests added to `spec/models/job_posting_spec.rb` under a new `.hybrid_search` describe block: keyword-only match (distinctive title text, no embedding), vector-only match (embedding set to the stubbed query embedding, title/body with no keyword overlap), a non-matching control posting excluded from both, and the empty-query-text -> none case.

Run full RSpec suite (root + packages/ingestion) before finalizing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented as three private-class-method-backed steps (fused_candidate_ids -> fuse_rankings -> rank_scores) rather than one method, to satisfy RuboCop Metrics/AbcSize and Metrics/MethodLength -- the format-on-change pre-commit hook enforces these on every save, so this split happened during implementation, not as a separate refactor pass.

RRF k=60 is the standard default from IR literature (no score normalization needed since only rank position matters) -- not tuned/benchmarked against this dataset, flagged here in case match quality needs revisiting later.

Candidate pool size is limit*3 per underlying query, a fixed heuristic not exposed as a parameter -- simplest thing that gives fusion enough overlap room without adding a new public API surface.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added `JobPosting.hybrid_search(query_text, limit: 10)`, fusing the two previously-disconnected search paths (`search` keyword/trigram via pg_search, `semantic_search` vector/cosine via VectorIntelligence+pgvector) with Reciprocal Rank Fusion.

**Changed:** app/models/job_posting.rb (+method), spec/models/job_posting_spec.rb (+4 examples).

**Verified:**
- New `.hybrid_search` spec block: blank query -> none; both paths empty -> none; a keyword-only match and a vector-only match both surface while an unrelated control posting is excluded.
- Full RSpec suite (root spec/ + packages/ingestion/spec/): 603 examples, 0 failures -- no regression to existing `search`/`semantic_search`/`management_tier` callers.
- RuboCop clean (project's pre-commit hook enforces this).

**Not done / explicitly out of scope per the task:** no other model got fusion (Skill/CareerProfile/Resume); no change to the underlying pg_search config or pgvector index. RRF's k=60 constant and the limit*3 candidate pool are untuned defaults -- worth revisiting if real-world match quality on this dataset warrants it, but no evidence of a problem today.
<!-- SECTION:FINAL_SUMMARY:END -->
