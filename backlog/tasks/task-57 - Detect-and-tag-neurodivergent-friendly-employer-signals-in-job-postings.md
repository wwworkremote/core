---
id: TASK-57
title: Detect and tag neurodivergent-friendly employer signals in job postings
status: To Do
assignee: []
created_date: '2026-08-17 00:59'
updated_date: '2026-09-03 19:08'
labels: []
dependencies: []
priority: medium
type: feature
ordinal: 63000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add detection + tagging for job postings whose text signals a neurodivergent-friendly employer (neurodivergent-aware / -friendly language, explicitly offered accommodations, inclusive-hiring statements, etc.), so matching can surface these postings rather than only filtering out irrelevant roles.

Nothing in the pipeline currently detects or tags this. The closest existing infrastructure is TASK-53's `LLM::ProfileMatcher` `match_tags` (`app/services/LLM/profile_matcher/prompt_builder.rb`'s OUTPUT_FORMAT, and `JobPosting.by_match_score`'s tag display) -- extending that prompt to recognize and tag neurodivergent-friendly language when present in a posting's body is the most natural integration point, reusing the same tag-badge UI already built for match criteria, rather than building a separate parallel system.

Needs real example postings that use this language to calibrate the prompt against (same "live-verify, don't guess" discipline as the extension work) -- gather a few real accommodating job descriptions first to see what language actually gets used in practice before writing detection logic.
<!-- SECTION:DESCRIPTION:END -->
