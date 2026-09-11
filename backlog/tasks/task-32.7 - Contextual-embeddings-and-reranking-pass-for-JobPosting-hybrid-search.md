---
id: TASK-32.7
title: Contextual embeddings and reranking pass for JobPosting hybrid search
status: To Do
assignee: []
created_date: '2026-08-14 17:06'
labels: []
milestone: m-0
dependencies:
  - TASK-32.1
references:
  - 'https://www.anthropic.com/news/contextual-retrieval'
parent_task_id: TASK-32
priority: low
type: enhancement
ordinal: 45000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Goal: task-32.1 shipped Reciprocal Rank Fusion combining pg_search (keyword) and pgvector (embedding) results into `JobPosting.hybrid_search`, but two gaps from that work remain unaddressed:

1. Embeddings are generated from raw text (title/body, and separately Resume/ExperienceHighlight content) in isolation, with no surrounding context prepended before embedding. Anthropic's published "Contextual Retrieval" research (Sept 2024 engineering blog) found that prepending a short chunk-specific context string before embedding measurably reduces retrieval failure, especially when combined with hybrid keyword+vector search -- which this codebase already has as of task-32.1.
2. task-32.1's own implementation notes flag RRF's k=60 constant and the limit*3 candidate pool as untuned defaults with no reranking pass after fusion -- rank quality currently relies entirely on fusion heuristics, not an actual relevance judgment over the fused candidate pool.

This task is to evaluate, and where it demonstrably improves match quality, implement: (a) contextual prefixing before embedding for JobPosting and/or Resume/ExperienceHighlight content, and (b) a reranking step applied to hybrid_search's fused candidate pool before truncating to the requested limit.

Scope: `JobPosting.hybrid_search` (task-32.1) and the embedding inputs that feed it. Do not extend to Skill or CareerProfile embeddings in this task -- a natural follow-up if this proves valuable there too.

Out of scope: picking a specific reranker model/provider -- that's an implementation decision for whoever picks this up, informed by what's already available via `LLM::Orchestrator`/`ruby_llm`. Do not add a new embedding provider or vector index type -- reuse the existing `neighbor`/`pgvector` setup.

This was surfaced during a job-search-system analysis session (2026-08-14), not from a live match-quality complaint -- treat the acceptance criteria's before/after comparison as the gate for whether to implement (b) at all, not a formality.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A documented before/after comparison (informal is fine) shows whether contextual prefixing changes retrieval quality on a representative sample of JobPosting and/or Resume content
- [ ] #2 Decision to adopt or explicitly reject contextual prefixing is recorded with reasoning, even if the outcome is not worth it at this data volume
- [ ] #3 If contextual prefixing is adopted, embedding generation for the in-scope model(s) prepends a short generated context string before the text is embedded
- [ ] #4 If reranking is adopted, JobPosting.hybrid_search applies it to the fused candidate pool before truncating to the requested limit, and existing callers continue to work unchanged
- [ ] #5 Decision to adopt or explicitly reject reranking is recorded with reasoning
- [ ] #6 Full RSpec suite (root spec/ and packages/ingestion/spec/) passes
<!-- AC:END -->
