---
id: TASK-32.5
title: Generalize management-tier filter into role-family filtering in JobPostings UI
status: Done
assignee:
  - claude
created_date: '2026-08-08 15:50'
updated_date: '2026-08-08 17:38'
labels: []
milestone: m-0
dependencies:
  - TASK-32.3
parent_task_id: TASK-32
priority: medium
type: enhancement
ordinal: 36000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Goal: replace the single binary `management_tier` scope and `@tier == "management"` filter (app/models/job_posting.rb, app/controllers/job_postings_controller.rb) with filtering by any role family from the task-32.3 taxonomy, so users can filter/browse postings by role family (e.g. "staff-plus IC", "engineering management") instead of only a management/non-management toggle.

Depends on task-32.3 (role-family taxonomy map): this task consumes that task's lookup API to build the filter scope. Do not start until task-32.3 is Done.

Scope: JobPosting scope + JobPostingsController + the minimal view change needed to expose the new filter option(s) to match how the existing management-tier toggle is currently exposed. Do not redesign the broader JobPostings UI/filtering panel beyond what's needed to add role-family selection alongside (or replacing) the existing tier toggle.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 JobPosting supports filtering by any role family defined in task-32.3's taxonomy, not just a management/non-management binary
- [x] #2 The existing management-tier filter's user-visible behavior is preserved or has a clear equivalent under the new role-family filtering (no silent loss of the current filter option)
- [x] #3 RSpec/request-spec coverage exercises filtering by at least two different role families and confirms postings outside any selected family are excluded
- [x] #4 Full RSpec suite passes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Investigated current wiring: `JobPostingsController#assign_filter_params` reads `params[:tier]`, `#apply_query_and_tier` applies `scope.management_tier if @tier == "management"`. The view (`app/views/job_postings/index.html.erb`) has exactly one toggle button (lines 5-11) and one "Tier: Management/Leadership" active-filter badge (lines 30-34) -- both wired to that single param. Only one caller of `management_tier`/`MANAGEMENT_TIER_TITLE_PATTERN` exists anywhere (confirmed by grep): this controller. Once it's replaced, both become fully dead code.

Decision: DELETE `MANAGEMENT_TIER_TITLE_PATTERN` and the `management_tier` scope from JobPosting, and their spec block, rather than leaving them orphaned alongside the new mechanism. This follows directly from the task title ("Generalize management-tier filter into role-family filtering") and AC #1's "not just a management/non-management binary" -- leaving two parallel unused/used mechanisms side by side is worse than either. Flagging this explicitly since it's a real decision (same as the ltree/ApiGuard corrections in 32.2/32.4), not silent scope creep -- it's the direct, necessary consequence of "generalize."

Implementation:
- `JobPosting.by_role_family(family)` scope: builds a parameterized `title ILIKE ?` OR-chain from `RoleFamily.aliases_for(family)` (same DB-level idiom as the old scope, just data-driven instead of one hardcoded regex). Returns `none` for an unknown/empty family rather than an unfiltered scope, so a bad param can't silently return everything.
- Controller: rename `@tier`/`params[:tier]` to `@role_family`/`params[:role_family]`, validated against `RoleFamily::FAMILIES.keys.map(&:to_s)` before use (trust boundary -- user-controlled query param) so an unrecognized value is treated as absent rather than passed through.
- Controller adds a small `ROLE_FAMILY_LABELS` constant (5 short display labels) exposed via `helper_method` for the view -- kept local to this controller rather than extending the already-Done `RoleFamily` module, since it's UI-label-specific, not taxonomy data.
- View: replace the single management toggle button with one small pill/button per family (5 total, same visual treatment as the existing button), and replace the "Tier: Management/Leadership" active-filter badge with "Role: <label>" driven by the same label map. All other filters (query, company, source_id) and their link_to param-passing are otherwise unchanged -- explicitly not redesigning the panel beyond this.

Tests: `spec/models/job_posting_spec.rb` -- replace the `.management_tier` block with a `.by_role_family` block (two families exercised, a non-matching posting excluded, unknown family -> none). `spec/requests/job_postings_spec.rb` (existing request spec, checked it exists) -- add coverage for `role_family` param filtering end-to-end through the controller for at least two families, confirming AC #3.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified live against the running dev server (localhost:31000, not just specs): GET /job_postings renders all 5 role-family toggle buttons with correct labels/links; GET /job_postings?role_family=engineering_management returns 200 and shows the 'Role: Engineering Mgmt' active-filter badge; GET /job_postings?role_family=bogus returns 200 with no active filters shown (invalid value silently ignored, not passed through to the scope, no error) -- confirms the trust-boundary validation in valid_role_family_param works end-to-end, not just at the unit level.

Confirmed via grep that MANAGEMENT_TIER_TITLE_PATTERN, management_tier, params[:tier], and @tier have zero remaining references anywhere in app/, packages/, or spec/ after this change -- clean deletion, no orphaned dead code left behind.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced the binary `management_tier` scope/`tier=management` param with general role-family filtering across 5 families from `RoleFamily` (task-32.3).

**Changed:**
- app/models/job_posting.rb -- deleted `MANAGEMENT_TIER_TITLE_PATTERN` and `management_tier` scope (only caller was this controller; leaving them would be orphaned dead code, see plan for reasoning); added `JobPosting.by_role_family(family)` (parameterized `title ILIKE` OR-chain over `RoleFamily.aliases_for(family)`, returns `none` for an unknown/empty family).
- app/controllers/job_postings_controller.rb -- `@tier`/`params[:tier]` -> `@role_family`/`params[:role_family]`, validated against `ROLE_FAMILY_LABELS.keys` (new 5-entry display-label constant, local to this controller) before use; unrecognized values are silently ignored rather than passed through.
- app/views/job_postings/index.html.erb -- one toggle button per family (was one button); active-filter badge shows "Role: <label>" (was "Tier: Management/Leadership"); all other filter links updated from `tier: @tier` to `role_family: @role_family`.
- spec/models/job_posting_spec.rb -- `.management_tier` block replaced with `.by_role_family` (two families independently, unknown family -> none).
- spec/requests/job_postings_spec.rb -- tier=management request spec replaced with two role_family specs (engineering_management, staff_plus_ic) plus a new one covering the invalid-value case.

**Verified:**
- New/changed specs: 31 examples, 0 failures (spec/models/job_posting_spec.rb + spec/requests/job_postings_spec.rb together).
- Full RSpec suite (root + packages/ingestion): 617 examples, 0 failures.
- Live-server check against the running dev app (not just specs): all 5 toggle buttons render correctly; filtering by role_family works end-to-end; an invalid role_family value returns 200 and is silently ignored, not a crash or a silent full-scope leak.
- grep confirms zero remaining references to the old tier mechanism anywhere in the codebase.

**Not done:** did not touch the broader filtering panel (query/company/source_id) beyond updating their param-forwarding from tier to role_family, per the task's explicit scope boundary.
<!-- SECTION:FINAL_SUMMARY:END -->
