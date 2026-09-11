---
id: TASK-62
title: Tinder-style swipe triage view for winnowing large job posting lists
status: Done
assignee: []
created_date: '2026-08-17 12:23'
updated_date: '2026-08-18 19:40'
labels: []
dependencies: []
modified_files:
  - app/controllers/job_posting_triage_controller.rb
  - app/controllers/admin/pipeline_steps_controller.rb
  - app/views/job_posting_triage/show.html.erb
  - app/views/layouts/application.html.erb
  - app/javascript/controllers/triage_controller.js
  - config/routes.rb
  - config/locales/en.yml
  - db/migrate/20260818171058_add_reason_tags_to_pipeline_steps.rb
  - spec/requests/job_posting_triage_spec.rb
  - spec/requests/admin/pipeline_steps_spec.rb
priority: medium
type: feature
ordinal: 67000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Noted mid-session for later, not started. Idea: a dedicated one-at-a-time review UI for job_postings -- swipe/click left for Not Interested (TASK-59 hooked this up: ignore), right to Favorite, maybe a third gesture for Expired (TASK-59) -- to burn through a large backlog of untriaged postings quickly instead of the current list view where each action is a separate button click on a card.

Needs design/UX decisions before implementation: keyboard shortcuts vs. actual swipe gestures, whether it's a new route/view or a mode on job_postings#index, what the "queue" ordering is (newest first? match score?), and whether skipping (no action) advances without changing status.

Refined 2026-08-17 with more detail from the user: the goal is specifically to cut through noise fast for a large volume of postings, so the queue should exclude anything already triaged (favorited, or any other non-"none" status) -- it's a first-pass winnowing tool, not a replacement for the full pipeline/show page. Each swipe should optionally capture structured signal for future analysis, not just the binary status change: a couple of multiple-choice criteria (e.g. "good match on industry, bad match on skill set/seniority" -- exact criteria list needs design) plus an optional free-text note, attached to the resulting pipeline_step so the reasoning behind a decision is queryable later, not just the decision itself.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Dedicated route/view (not an index mode) at GET /job_postings/triage shows one un-triaged posting at a time, queue = JobPosting.where(status: "none").recent, oldest-unseen-first via recency order
- [x] #2 Keyboard shortcuts (F=favorite, N=not interested, E=expired, S=skip) drive the three decisions plus skip; click/tap buttons are the accessible equivalent -- no drag/touch swipe gesture library
- [x] #3 Skip is a session-scoped no-op: status is unchanged, the posting is added to session[:triage_skipped_ids] so it doesn't reappear this session, but no DB row is written
- [x] #4 Each decision can optionally capture up to 4 good/bad criteria (industry, skills/seniority, compensation, location/remote) plus a free-text note, stored on the resulting pipeline_step's new reason_tags jsonb column (migration added) so it's queryable later, not just composed into note text
- [x] #5 Admin::PipelineStepsController#create reused for recording the decision (extended to accept reason_tags + custom note + redirect back to the triage queue), not a duplicate endpoint
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Design decisions (resolving the open questions in the description):

1. **Dedicated route, not an index mode.** `GET /job_postings/triage` -> new `JobPostingTriageController#show`. The index is a paginated multi-record browse; triage is single-record full-focus review -- different enough layouts/interactions that bolting a "mode" onto JobPostingsController (already near the ClassLength budget after TASK-67) would fight the grain. Mirrors the existing pattern of small single-purpose controllers (Admin::PipelineStepsController, Admin::ContactsController).

2. **Keyboard-primary, not touch/drag swipe.** This is a desktop power-user tool (confirmed via TASK-67's framing) -- a real drag-gesture implementation is JS complexity this page doesn't need. F/N/E/S keys drive Favorite/Not-interested/Expired/Skip; on-screen buttons are the same actions for click users. No new JS dependency.

3. **Queue = JobPosting.where(status: "none").recent** (excludes anything already triaged, matches "first-pass winnowing tool" framing from the refined description). No match-score ordering for v1 -- would require the match-score join for every candidate; recency is simpler and matches the index's default.

4. **Skip is a session-only no-op, not a DB write.** Marking "skipped" in the DB would need a new column/table for something that isn't really a triage decision. session[:triage_skipped_ids] (array of ids) is enough to keep a skipped posting from reappearing in the same session without touching JobPosting#status or creating a pipeline_step.

5. **Structured signal: 4 criteria (industry, skills/seniority, compensation, location/remote), each optional good/bad, plus free-text note** -- per user decision 2026-08-18. Stored as `pipeline_steps.reason_tags` jsonb (migration added: `20260818171058_add_reason_tags_to_pipeline_steps.rb`), not composed into the note string, so future queries can filter on real keys (e.g. `where("reason_tags->>'industry' = 'bad'")`).

6. **Reuse Admin::PipelineStepsController#create** for recording the decision instead of a new endpoint -- it already does the AASM transition + pipeline_step creation + ahoy tracking. Extend `log_status_change_step` to accept optional `reason_tags` (whitelisted hash, not raw params mass-assignment) and a custom `note` (falls back to the existing "Status changed to X" default when triage doesn't send one), and add a redirect branch for `params[:from_triage] == "true"` that goes back to the triage queue instead of the job posting's own show page or the index-card-removal turbo_stream path. Existing index Favorite/Ignore/Expired buttons are unaffected -- they don't send these new params.

Skipped: swipe/drag gestures, a persisted "skip log" table, match-score queue ordering, mobile-specific touch handling -- add later only if the keyboard/click flow proves too slow in practice.
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built per the design decisions in the plan: a dedicated `GET /job_postings/triage` route (new `JobPostingTriageController`, not a mode on the already-sizeable `JobPostingsController`) showing one `status: "none"` posting at a time, ordered by recency. F/N/E/S keyboard shortcuts (Stimulus `triage_controller.js`, ignored while typing in the note field) plus on-screen buttons drive Favorite/Not-interested/Expired/Skip -- no drag/touch gesture library. Skip is a session-only no-op (`session[:triage_skipped_ids]`), with a `reset_skips` escape hatch in the empty state.

Decisions recorded via the existing `Admin::PipelineStepsController#create` (extended, not duplicated): accepts an optional `reason_tags` hash (4 criteria -- industry, skills/seniority, compensation, location/remote -- each good/bad, whitelisted by key against mass-assignment junk) and a custom `note` overriding the default "Status changed to X", stored on a new `pipeline_steps.reason_tags` jsonb column (migration `20260818171058`) so it's queryable later (`reason_tags->>'industry'`), not just composed into free text. Added a `from_triage` redirect branch back to the queue.

Found and fixed a real bug during manual testing: RuboCop's `Rails/StrongParametersExpect` autocorrect rewrote `params[:reason_tags].permit(...)` into `params.expect(:reason_tags).permit(...)`, which is wrong for a Hash-shaped param (`expect` treats a bare key as a required scalar and raises `ActionController::ParameterMissing`) -- broke the whole triage-decision flow silently (status transitioned via AASM but the pipeline_step, and its reason_tags, never got created) until caught via network-request inspection in-browser. Fixed with a scoped `rubocop:disable Rails/StrongParametersExpect` and a comment explaining why. Also found the dev server on :31000 wasn't reflecting code changes reliably; restarted it clean mid-session -- flagging in case that surprises whoever's using it next.

Verified end-to-end in-browser: keyboard shortcut submits with correct reason_tags/note persisted, skip excludes without mutating status, criteria+note UI renders correctly (also fixed a stale Tailwind build that was mangling the layout). 17 new/extended request spec examples pass; full request suite (243 examples) green; rubocop and brakeman clean.
<!-- SECTION:FINAL_SUMMARY:END -->
