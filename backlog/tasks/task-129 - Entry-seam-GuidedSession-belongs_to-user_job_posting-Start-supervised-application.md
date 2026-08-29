---
id: TASK-129
title: >-
  Entry seam: GuidedSession belongs_to user_job_posting + "Start supervised
  application"
status: To Do
assignee: []
created_date: '2026-08-29 20:45'
labels:
  - application-capture-datalake
  - 'wayfinder-map:doc-7'
dependencies: []
references:
  - docs/adr/010-link-to-application-capture-and-the-datalake.md
  - >-
    backlog/docs/wayfinder/doc-7 -
    Wayfinder-map-link-to-application-capture-and-the-datalake.md
priority: medium
type: feature
ordinal: 145000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implements ADR 010 §1 (entry seam) and §2 (correlation spine). Connects a JobPosting to a GuidedSession so the harness is reachable as one continuous path from a posting link.

Advisory only — starting or completing a session never auto-changes UserJobPosting AASM state.

## Scope

- Migration: `guided_sessions.user_job_posting_id` (nullable, indexed, FK). `GuidedSession belongs_to :user_job_posting, optional: true`; `UserJobPosting has_many :guided_sessions`.
- "Start supervised application" affordance on `job_postings/show`: creates the `UserJobPosting` if none exists for the current user, then a `GuidedSession` linked to it, then redirects to `guided_sessions#show` (or the tracked source URL, matching the current new-session flow).
- Correlation spine: the extension stamps `guided_session_token` onto the four trace_id capture-table rows (`application_field_observations`, `application_field_mappings`, `application_field_answers`, `extension_error_events`) and the materialized `Scenario` during a guided session. Add the column/attribute where the capture endpoints write, populated from the `?guided_session_token=` the extension already carries. No backfill onto historical rows.
- On `GuidedSession#complete!`: if the linked `UserJobPosting` has a legal next AASM transition that completion implies (e.g. `apply`), enqueue a `HumanTask` proposing it — do not perform it.
- `extension/manifest.json` version bump (minor — new message field on the capture path).

## Out of scope

- The legibility badge/card/index (TASK-128 — depends on this).
- The datalake asset endpoint (TASK-126).
- Any change to non-guided capture paths or `application_trace_id` semantics.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Migration adds nullable indexed guided_sessions.user_job_posting_id with a FK; GuidedSession belongs_to :user_job_posting (optional), UserJobPosting has_many :guided_sessions; a spec covers the nil case
- [ ] #2 'Start supervised application' on job_postings/show creates the UserJobPosting when absent, creates a linked GuidedSession, and lands on the session view; a request spec covers both 'UserJobPosting exists' and 'does not exist' paths
- [ ] #3 During a guided session the four trace_id capture tables and the materialized Scenario carry the guided_session_token; a spec asserts a non-guided capture is unaffected and no historical row is backfilled
- [ ] #4 GuidedSession#complete! enqueues a HumanTask proposing the implied UserJobPosting transition and never calls the AASM event itself; a spec asserts state is unchanged after complete!
- [ ] #5 extension/manifest.json version bumped; the token-stamping change is covered by an extension-side check or documented manual step
- [ ] #6 brakeman + rubocop -a clean
<!-- AC:END -->
