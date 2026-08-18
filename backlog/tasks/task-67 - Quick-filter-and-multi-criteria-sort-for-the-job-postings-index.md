---
id: TASK-67
title: Quick filter and multi-criteria sort for the job postings index
status: To Do
assignee: []
created_date: '2026-08-17 23:36'
labels:
  - ux
  - job-postings
dependencies: []
documentation:
  - >-
    /Users/mike/Desktop/inbox/inspiration/agentic-platform-lessons-2026-08-12/31-global-command-palette-and-keyboard-navigation/lesson.md
type: enhancement
ordinal: 76000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The job_postings index (JobPostingsController#index / app/views/job_postings/index.html.erb) already supports several filter params (q, company, source_id, role_family, location, remote, contract) and one sort option (match_score, via JobPosting.by_match_score), with active-filter chips. In practice, paging deep into results (e.g. page=12 with several filters set) to find something specific is still a pain -- the current filter bar requires deliberate form interaction rather than fast, low-friction narrowing, and there's only one alternative to the default recency sort.

User framing to keep in mind for this and future UI work on this app: WWWorkRemote is deliberately the intersection of an admin/data-management tool and a browsing/product interface, built for one local power user -- not a simplified consumer product. Favor dense, fast, keyboard-friendly affordances over hiding complexity.

Design inspiration flagged by the user: a global Cmd+K-style command palette pattern, documented at /Users/mike/Desktop/inbox/inspiration/agentic-platform-lessons-2026-08-12/31-global-command-palette-and-keyboard-navigation/lesson.md -- keyboard shortcut opens an instant modal search/filter overlay backed by a fast index, supporting direct-jump navigation. Whether this task adopts that exact pattern (a global palette) versus a more conventional inline quick-filter bar with additional sort options is a design decision to make before implementation, not a foregone conclusion -- evaluate both against this specific index page's needs (large result sets, existing filter params, existing sort infrastructure) rather than assuming the palette pattern is the right fit wholesale.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Users can narrow the job postings list without a full page reload per keystroke/interaction (debounced live filtering, a command-palette-style overlay, or equivalent -- exact mechanism is a design decision for the implementer)
- [ ] #2 At least one additional sort option beyond recency and match_score is available (e.g. company, freshness/published date, location) with clear labeling of the active sort
- [ ] #3 Existing filter params (q, company, source_id, role_family, location, remote, contract) and active-filter chips continue to work unchanged
- [ ] #4 The chosen approach is documented as a design decision in the task's implementation plan before building, given the open question between a global palette vs. an inline quick-filter bar
<!-- AC:END -->
