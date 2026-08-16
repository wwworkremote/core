---
id: TASK-53
title: Relevance ranking + explainable criteria tags for JobPosting
status: Done
assignee: []
created_date: '2026-08-16 15:21'
updated_date: '2026-08-16 16:01'
labels: []
dependencies:
  - TASK-52
references:
  - app/services/LLM/profile_matcher.rb
  - app/models/job_posting.rb
priority: medium
type: feature
ordinal: 59000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
User: "Rank job postings. Add a number of criteria and tag jobs for what those criteria are that will be relevant to me so it is easier for me to sort through and manage my job postings... Evaluate like a human."

Investigated (fork aca3fd9eb676b5cc4): no relevance_score/ranking/match_score field exists anywhere on JobPosting today. LLM::ProfileMatcher (app/services/LLM/profile_matcher.rb) is a real, already-built "evaluate like a human" holistic assessment -- but it's on-demand, single-posting, user-triggered, writes free-text data (user_job.match_analysis), not a numeric score, and isn't surfaced as a sort option on the index. This task is genuinely new work, not a gap in existing infrastructure like TASK-52 was.

Sequenced after TASK-52 (role-title auto-ignore) per explicit user direction -- ranking postings that should have been auto-ignored in the first place is wasted design effort.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Numeric match_score and match_tags persisted as real, sortable/indexed columns on user_job_postings, not thrown away like the pre-existing behavior did
- [x] #2 Job postings index page supports ?sort=match_score, showing scored postings highest-first and unscored postings after (not dropped)
- [x] #3 Each card shows its score and tags when sorted this way, so it's actually usable for triage, not just sortable in the abstract
- [x] #4 LLM::ProfileMatcher's existing 'evaluate like a human' prompt (remote purity, tech-stack density, seniority alignment, red flags) extended with an explicit TAGS output line, reusing the existing evaluation criteria rather than inventing new ones
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Extended existing infrastructure rather than building a parallel system -- LLM::ProfileMatcher already computed a MATCH_CONFIDENCE score and evaluated real criteria (remote purity, tech-stack density, seniority alignment, red flags), it just discarded the score except for a boolean priority_flag and never persisted tags at all.

Migration: user_job_postings gains match_score (integer, indexed) and match_tags (text array) -- real columns, not user_job_postings.strategy jsonb (already used by a separate concern, JobBoards::StrategyAgent).

PromptBuilder's OUTPUT_FORMAT gained an explicit TAGS line (2-6 kebab-case tags). ProfileMatcher now extracts and persists both match_score and match_tags via regex parsing (same technique as the existing MATCH_CONFIDENCE extraction).

JobPosting.by_match_score(user) scope + JobPostingsController's ?sort=match_score: unscored postings stay in the list (LEFT JOIN, not INNER), sorted after scored ones (NULLS LAST). Live-verified via curl against a real dev posting: score+tags badge renders correctly on the card, sort toggle preserves through pagination and other filters.

Real bug caught by a test, not shipped: the first version filtered the JOIN's user scoping in a WHERE clause (`user_job_postings.user_id IN (user.id, nil)`), which silently DROPPED a posting entirely whenever a different user had a row for it (LEFT JOIN found that row, WHERE then rejected it since it matched neither this user's id nor NULL) instead of showing it unscored. Fixed by moving the user_id condition into the JOIN's own ON clause via a raw SQL join with sanitize_sql_array, not a WHERE filter -- caught by a "does not double-count a posting scored by a different user" spec written specifically to probe this. Also found and fixed a related issue in the same pass: .count doesn't work on this scope (Postgres rejects wrapping the custom multi-column .select in COUNT(...)) -- confirmed Kaminari's real pagination path (.total_count) avoids this internally and is unaffected; only a naive .count on the raw relation would hit it, documented in the spec that found it.

Verified: full combined suite (spec + packages/ingestion/spec) -- 726 examples, 0 failures, 91.20% coverage. RuboCop and erb_lint clean on every touched file.
<!-- SECTION:FINAL_SUMMARY:END -->
