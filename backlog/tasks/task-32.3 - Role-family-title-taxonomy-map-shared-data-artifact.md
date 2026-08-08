---
id: TASK-32.3
title: Role-family title taxonomy map (shared data artifact)
status: To Do
assignee: []
created_date: '2026-08-08 15:49'
labels: []
milestone: m-0
dependencies: []
parent_task_id: TASK-32
priority: high
type: feature
ordinal: 34000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Goal: replace the single hand-rolled `JobPosting::MANAGEMENT_TIER_TITLE_PATTERN` regex (app/models/job_posting.rb) -- currently a binary "is this a management title" check used only by the `management_tier` scope / the `@tier == "management"` filter in JobPostingsController -- with a general role-family taxonomy that groups adjacent/lateral title strings under shared families (e.g. a "staff-plus IC" family covering "Staff Engineer", "Staff Software Engineer", "Principal Engineer"; an "engineering management" family covering "Engineering Manager", "Director of Engineering", "Group Engineering Manager", "VP Engineering", etc).

This is a shared data artifact consumed by two downstream subtasks (ingestion query expansion, and generalized UI filtering) -- it must land before either of those can start. It is not itself a search or filtering feature; it's the lookup table/module those features are built on.

Context: search/match ranking (JobSearchManager::MatcherService, VectorIntelligence) is already semantic (embedding-based) and doesn't need this to work well. The actual problem this solves is (a) at ingestion time, job-board queries (BoardQuery#terms, DataAcquisitionManager::CrawlDefaults) currently send one literal keyword per board, so postings with a different-but-equivalent title wording are never fetched at all, and (b) in the UI, only one binary tier distinction exists today.

Keep this lazy: a role-family list is a lookup table, not an ML classifier or an LLM categorization pass. Do not have this task modify BoardQuery, CrawlDefaults, JobPosting's scopes, or JobPostingsController -- those are separate downstream subtasks that depend on this one's output.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A defined, named set of role families exists in the codebase (e.g. as a Ruby constant/module or config file), each mapping a family identifier to a list of title-string aliases/patterns
- [ ] #2 The role-family set covers at minimum: staff-plus IC titles, engineering management titles (superseding the exact strings currently in MANAGEMENT_TIER_TITLE_PATTERN), and at least one additional adjacent family relevant to this codebase's job domain (e.g. product/design/data leadership) -- reviewed against real title strings already present in JobPosting data, not invented from scratch
- [ ] #3 A lookup method exists that, given a title string, returns which family (if any) it belongs to, and given a family identifier, returns its alias list
- [ ] #4 RSpec coverage for the lookup method covering exact matches, case-insensitivity, and titles that belong to no family
- [ ] #5 No existing behavior changes yet -- MANAGEMENT_TIER_TITLE_PATTERN and management_tier scope remain functional and untouched by this task
<!-- AC:END -->
