---
id: TASK-67
title: Quick filter and multi-criteria sort for the job postings index
status: Done
assignee: []
created_date: '2026-08-17 23:36'
updated_date: '2026-08-18 17:04'
labels:
  - ux
  - job-postings
dependencies: []
documentation:
  - >-
    /Users/mike/ai/inbox/inspiration/agentic-platform-lessons-2026-08-12/31-global-command-palette-and-keyboard-navigation/lesson.md
modified_files:
  - app/controllers/job_postings_controller.rb
  - app/models/job_posting.rb
  - app/views/job_postings/index.html.erb
  - app/javascript/controllers/filter_form_controller.js
  - config/locales/en.yml
type: enhancement
ordinal: 76000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The job_postings index (JobPostingsController#index / app/views/job_postings/index.html.erb) already supports several filter params (q, company, source_id, role_family, location, remote, contract) and one sort option (match_score, via JobPosting.by_match_score), with active-filter chips. In practice, paging deep into results (e.g. page=12 with several filters set) to find something specific is still a pain -- the current filter bar requires deliberate form interaction rather than fast, low-friction narrowing, and there's only one alternative to the default recency sort.

User framing to keep in mind for this and future UI work on this app: WWWorkRemote is deliberately the intersection of an admin/data-management tool and a browsing/product interface, built for one local power user -- not a simplified consumer product. Favor dense, fast, keyboard-friendly affordances over hiding complexity.

Design inspiration flagged by the user: a global Cmd+K-style command palette pattern, documented at /Users/mike/ai/inbox/inspiration/agentic-platform-lessons-2026-08-12/31-global-command-palette-and-keyboard-navigation/lesson.md -- keyboard shortcut opens an instant modal search/filter overlay backed by a fast index, supporting direct-jump navigation. Whether this task adopts that exact pattern (a global palette) versus a more conventional inline quick-filter bar with additional sort options is a design decision to make before implementation, not a foregone conclusion -- evaluate both against this specific index page's needs (large result sets, existing filter params, existing sort infrastructure) rather than assuming the palette pattern is the right fit wholesale.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Users can narrow the job postings list without a full page reload per keystroke/interaction (debounced live filtering, a command-palette-style overlay, or equivalent -- exact mechanism is a design decision for the implementer)
- [x] #2 At least one additional sort option beyond recency and match_score is available (e.g. company, freshness/published date, location) with clear labeling of the active sort
- [x] #3 Existing filter params (q, company, source_id, role_family, location, remote, contract) and active-filter chips continue to work unchanged
- [x] #4 The chosen approach is documented as a design decision in the task's implementation plan before building, given the open question between a global palette vs. an inline quick-filter bar
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Design decision (AC #4): inline quick-filter bar, not a global command palette.

Rationale: this page already has a full filter form (q, company, source_id, role_family, location, remote, contract), server-side pagination, and Turbo+Stimulus+importmap already loaded app-wide (no new JS deps). A command palette needs a new fast search index, a modal overlay, and global keybinding capture -- none of which exists here and none of which this index page's filter set (structured params, not free-text jump-to-record) actually needs. The lazy, correct-for-this-page move is:

1. Wrap the results grid + pagination in a `turbo_frame_tag "job_postings_results"`.
2. Add a small Stimulus controller (`filter_form_controller.js`) that debounces (~300ms) and calls `form.requestSubmit()` on input/change for q, location, remote, contract -- turning every keystroke/toggle into a frame-scoped GET that replaces just the results, not a full page reload.
3. Point the form's `data-turbo-frame` at that frame id so submits (manual Enter/submit button included) target it too.
4. Add sort options beyond match_score: company (alpha) and published_at (freshness, explicit -- since recent is already published_at DESC, add company as the second option and keep sort labeling clear in the chip UI).
5. All existing params/chips continue through `active_filter_params` unchanged -- no param renames.

Skipped: command palette, cmd+k global shortcut, client-side search index -- add later only if the power-user workflow actually demands cross-entity jump-to, not just narrowing this one list.
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Inline quick-filter bar (design decision documented in the plan, not a command palette). The search/location/remote/contract form now debounces (~300ms) via a new Stimulus controller and auto-submits into a `turbo_frame_tag "job_postings_results"` wrapping the sort/role chips, active-filter chips, results, and pagination -- so narrowing the list updates in place without a full page reload, and `data-turbo-action: advance` keeps the URL bar/history in sync. Added a "Sort by Company" option (`JobPosting.by_company` scope, alphabetical) alongside the existing match_score sort. Kept the source-not-interested button_to escaping the frame (`turbo_frame: "_top"`) since it hits a different controller. Verified in-browser: live search narrows results and updates chips together, sort-by-company toggle preserves the active query param (the exact stale-params bug the single-frame restructuring was meant to prevent), company sort produces correct alphabetical order, pagination still works inside the frame, no console errors. All 39 existing job_postings request specs still pass; rubocop clean.
<!-- SECTION:FINAL_SUMMARY:END -->
