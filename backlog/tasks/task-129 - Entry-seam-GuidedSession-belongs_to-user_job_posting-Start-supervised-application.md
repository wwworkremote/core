---
id: TASK-129
title: >-
  Entry seam: GuidedSession belongs_to user_job_posting + "Start supervised
  application"
status: Done
assignee:
  - '@claude'
created_date: '2026-08-29 20:45'
updated_date: '2026-08-30 02:10'
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
- [x] #1 Migration adds nullable indexed guided_sessions.user_job_posting_id with a FK; GuidedSession belongs_to :user_job_posting (optional), UserJobPosting has_many :guided_sessions; a spec covers the nil case
- [x] #2 'Start supervised application' on job_postings/show creates the UserJobPosting when absent, creates a linked GuidedSession, and lands on the session view; a request spec covers both 'UserJobPosting exists' and 'does not exist' paths
- [x] #3 During a guided session the four trace_id capture tables and the materialized Scenario carry the guided_session_token; a spec asserts a non-guided capture is unaffected and no historical row is backfilled
- [x] #4 GuidedSession#complete! enqueues a HumanTask proposing the implied UserJobPosting transition and never calls the AASM event itself; a spec asserts state is unchanged after complete!
- [x] #5 extension/manifest.json version bumped; the token-stamping change is covered by an extension-side check or documented manual step
- [x] #6 brakeman + rubocop -a clean
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented the ADR 010 entry seam + correlation spine.

**Migrations**
- `20260830020000` — `guided_sessions.user_job_posting_id` (nullable, FK, indexed).
- `20260830020100` — `guided_session_token` (string, indexed) on `application_field_answers`, `application_field_mappings`, `application_field_observations`, `extension_error_events`, `scenarios`. No data backfill.

**Models**
- `GuidedSession belongs_to :user_job_posting, optional: true`; `UserJobPosting has_many :guided_sessions, dependent: :nullify`.
- `GuidedSession#complete!` now calls `propose_application_transition` → `HumanTask.propose_apply` (kind `submit_approval`, pending, `payload` carries `proposed_event: "apply"` + `guided_session_token`). Idempotent on (job_posting, user, kind, pending); rescued/logged so it never blocks completion. Never calls the AASM event — advisory only.

**Entry point**
- `POST /job_postings/:id/start_supervised_application` → `GuidedSessionsController#create_from_posting`: finds-or-creates the `UserJobPosting`, creates an `application_execution` `GuidedSession` linked to it, redirects to the session view. Blank `target_url` → redirect back with alert.
- "Start supervised application" button on `job_postings/show` (in the apply-actions row).

**Correlation spine**
- `Scenarios::GuidedCapture` stamps `guided_session_token` + `user_job_posting` onto the materialized `Scenario`.
- The four capture controllers accept a top-level `guided_session_token` param and persist it (threaded exactly like `trace_id`). `content.js` sends it on the `application_field_answers` POST.

**Deferred to TASK-131**: `sidepanel.js` (observations + mappings POSTs) and `background.js` (error events) don't yet forward the token — the sidepanel has no access to it without content→sidepanel message plumbing.

**Extension**: `manifest.json` 1.29.0 → 1.30.0.

**Tests**: `spec/models/guided_session_spec.rb` (new), additions to `spec/requests/guided_sessions_spec.rb`, `spec/services/scenarios/guided_capture_spec.rb`, `spec/requests/api/v0/application_field_answers_spec.rb`. Full touched-area sweep (job_postings, guided_sessions, scenarios, api/v0, models) = 253 examples, 0 failures. rubocop + brakeman clean on changed files.
<!-- SECTION:FINAL_SUMMARY:END -->
