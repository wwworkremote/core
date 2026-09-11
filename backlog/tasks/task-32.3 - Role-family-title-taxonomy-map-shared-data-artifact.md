---
id: TASK-32.3
title: Role-family title taxonomy map (shared data artifact)
status: Done
assignee:
  - claude
created_date: '2026-08-08 15:49'
updated_date: '2026-08-08 16:36'
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
- [x] #1 A defined, named set of role families exists in the codebase (e.g. as a Ruby constant/module or config file), each mapping a family identifier to a list of title-string aliases/patterns
- [x] #2 The role-family set covers at minimum: staff-plus IC titles, engineering management titles (superseding the exact strings currently in MANAGEMENT_TIER_TITLE_PATTERN), and at least one additional adjacent family relevant to this codebase's job domain (e.g. product/design/data leadership) -- reviewed against real title strings already present in JobPosting data, not invented from scratch
- [x] #3 A lookup method exists that, given a title string, returns which family (if any) it belongs to, and given a family identifier, returns its alias list
- [x] #4 RSpec coverage for the lookup method covering exact matches, case-insensitivity, and titles that belong to no family
- [x] #5 No existing behavior changes yet -- MANAGEMENT_TIER_TITLE_PATTERN and management_tier scope remain functional and untouched by this task
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Researched real title strings before designing the taxonomy (per AC #2's "not invented from scratch"): sampled 4000 random JobPosting titles from the dev DB and grep-tested candidate family patterns against them. All 5 target families have real, plentiful matches (engineering management: 15+ distinct real titles like "Engineering Manager, Contracting Platform"; staff-plus IC: real examples included "Member of Technical Staff" and "Senior Staff Software Engineer", which I hadn't anticipated and are now included; product/design/data leadership: all represented).

Module: `app/services/role_family.rb`, `module RoleFamily` -- matches the existing sibling convention of `app/services/vector_intelligence.rb` (plain top-level module, no namespace, no persistence).

`RoleFamily::FAMILIES` is a Hash of `family_symbol => [alias strings]` (multi-word literal phrases, not single generic words like bare "Director" -- avoids false-positive collisions across families). `RoleFamily.for(title)` does case-insensitive substring matching of each alias against the title, returns the first matching family symbol or nil. `RoleFamily.aliases_for(family)` returns that family's alias list (empty array for unknown family).

5 families: staff_plus_ic, engineering_management, product_leadership, design_leadership, data_leadership -- exceeds AC #2's minimum of 2 (staff-plus IC + engineering management) plus 1 more.

Note on AC #2's "supersedes MANAGEMENT_TIER_TITLE_PATTERN": that old pattern flatly mixes IC roles (principal engineer, staff+) with real management (director/VP/chief officer/engineering manager) with architecture leads (platform lead, solutions architect) into one bucket. This taxonomy intentionally decomposes that into separate families rather than reproducing one flat bucket -- that's the actual point of replacing a binary tier with a taxonomy. "platform lead" and "solutions? architect" from the old pattern are not carried forward as their own family (too niche a bucket on their own) and are not force-fit into staff_plus_ic either, since real-world usage of those titles is genuinely closer to IC-track architecture than engineering seniority -- leaving them out is a deliberate scope call, not an oversight, and a future alias addition could fold them in if a concrete need shows up.

Tests: `spec/services/role_family_spec.rb` (new file, matches existing top-level `app/services/*.rb` -> `spec/services/*_spec.rb` convention) covering `.for` (exact real-title match per family, case-insensitivity, a title matching no family -> nil, blank title -> nil) and `.aliases_for` (known family returns its list, unknown family returns empty array).

Does not touch JobPosting, BoardQuery, CrawlDefaults, or JobPostingsController -- confirmed those are out of scope per the task description; downstream tasks 32.4/32.5 consume this module.
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added `RoleFamily` (app/services/role_family.rb), a plain lookup module grouping adjacent job titles into 5 families: staff_plus_ic, engineering_management, product_leadership, design_leadership, data_leadership. Each family maps to a literal alias-phrase list reviewed against 4000 real sampled JobPosting titles (not invented) -- e.g. staff_plus_ic includes "Member of Technical Staff", found only by checking real data, not something I'd have guessed.

**API:** `RoleFamily.for(title)` -- case-insensitive substring match against all families' aliases, returns the first matching family symbol or nil. `RoleFamily.aliases_for(family)` -- returns that family's alias list, empty array for an unknown family.

**Changed:** app/services/role_family.rb (new), spec/services/role_family_spec.rb (new, 7 examples).

**Verified:**
- New spec: real-title matches for two families, case-insensitivity, no-match -> nil, blank/nil -> nil, alias lookup for known and unknown families.
- Confirmed zero diff to app/models/job_posting.rb or app/controllers/job_postings_controller.rb -- MANAGEMENT_TIER_TITLE_PATTERN and management_tier untouched, per this task's explicit scope boundary.
- Full RSpec suite (root + packages/ingestion): 610 examples, 0 failures.

**Scope note:** intentionally did not carry forward "platform lead"/"solutions? architect" from the old MANAGEMENT_TIER_TITLE_PATTERN as their own family or fold them into staff_plus_ic -- see plan for reasoning. This taxonomy decomposes the old flat management-tier bucket into distinct families rather than reproducing it 1:1, which is the actual point of this task.

**Ready for downstream consumption:** task-32.4 (ingestion query expansion) and task-32.5 (UI filter) can now build on `RoleFamily`.
<!-- SECTION:FINAL_SUMMARY:END -->
