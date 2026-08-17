---
id: TASK-57
title: Surface neurodivergent-friendly (ADHD/Autism/AuDHD) signals in job matching
status: To Do
assignee: []
created_date: '2026-08-17 00:59'
labels: []
dependencies: []
priority: medium
type: feature
ordinal: 63000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Mike wants a way to identify job postings from companies that are explicitly supportive of neurodivergency (ADHD/Autism/AuDHD-aware/friendly language, accommodations mentioned, etc.), not just filter out irrelevant roles. Raised twice this session as a practical "how do I do this today" question with no existing lever in the codebase to answer it.

Nothing in the pipeline currently detects or tags this. The closest existing infrastructure is TASK-53's LLM::ProfileMatcher `match_tags` (app/services/LLM/profile_matcher/prompt_builder.rb's OUTPUT_FORMAT, and JobPosting.by_match_score's tag display) -- extending that prompt to recognize and tag neurodivergent-friendly language when present in a posting's body is the most natural integration point, reusing the same tag-badge UI already built for match criteria, rather than building a separate parallel system.

Needs real example postings that use this language to calibrate the prompt against (same "live-verify, don't guess" discipline as the extension work) -- a few real accommodating job descriptions should be gathered first to check what language actually gets used in practice (e.g. "neurodivergent-friendly," "we welcome applicants with ADHD/autism," explicit accommodation offers) before writing detection logic.
<!-- SECTION:DESCRIPTION:END -->
