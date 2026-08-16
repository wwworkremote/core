---
id: TASK-53
title: Relevance ranking + explainable criteria tags for JobPosting
status: To Do
assignee: []
created_date: '2026-08-16 15:21'
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
