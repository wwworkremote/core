---
id: TASK-63
title: Surface job postings you keep reopening but haven't triaged
status: To Do
assignee: []
created_date: '2026-08-17 23:01'
labels:
  - ux
  - analytics
dependencies: []
type: feature
ordinal: 68000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Ahoy visit/event data shows a recurring pattern: job postings get revisited across many separate browser sessions, sometimes spanning months, without ever being favorited/ignored/archived through the pipeline -- until they silently expire or get purged. One concrete case found in dev data: a posting viewed 23 times across 8 distinct visits over 115 days, never triaged, eventually auto-purged.

This means the page-revisit itself is functioning as an unofficial "save for later" mechanism, standing in for the pipeline's formal triage actions (favorite/ignore/archive/expire). Postings can currently disappear (via expiry or purge) before the user ever acts on them, discarding whatever attention was already invested.

The event data needed to detect this already exists in `ahoy_events` (`Viewed Job Posting`, keyed by `job_posting_id` and `visit_id`) -- no new instrumentation is required for this specific task. Surface a view/report that lists job postings viewed across 2+ distinct Ahoy visits whose `status` is still unresolved (e.g. "none"), so they're visible before they age out.

Consider whether this is better served by a small custom index/filter in the existing job_postings UI, or by a Blazer (github.com/ankane/blazer) dashboard/query -- this app already depends on several other ankane gems (ahoy_matey, ahoy_captain, chartkick, groupdate, pghero, neighbor) and chartkick+groupdate are already in the Gemfile, which are Blazer's own charting dependencies. Blazer isn't currently in the Gemfile; adding it is an explicit scope decision (new dependency, ad-hoc SQL execution surface, needs auth-gating under the admin namespace) and shouldn't be assumed without confirming with the user first.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A view (in-app filter/report, or a documented Blazer query/dashboard) lists job postings viewed across 2+ distinct Ahoy visits with an unresolved pipeline status
- [ ] #2 The list is reachable from existing navigation, not just a raw query result
- [ ] #3 Decision on custom-view vs. Blazer is documented with rationale, made in consultation with the user rather than assumed
<!-- AC:END -->
