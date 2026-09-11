---
id: TASK-93
title: Notify Mike when a pipeline item has been idle 2-3 days
status: Done
assignee: []
created_date: '2026-08-26 23:10'
updated_date: '2026-08-27 12:37'
labels: []
dependencies: []
modified_files:
  - app/models/user_job_posting.rb
  - app/controllers/home_controller.rb
  - app/views/home/index.html.erb
  - config/locales/en.yml
  - spec/models/user_job_posting_spec.rb
  - spec/requests/home_spec.rb
  - docs/architecture/pipeline-statechart.md
priority: medium
type: feature
ordinal: 108000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Leads/applications that go quiet risk being forgotten as the pipeline grows. Mike wants to be notified when a posting he's actively tracking hasn't had any pipeline activity in 2-3 days, so following up doesn't silently fall through. "Active" means it hasn't reached a terminal state (offered, rejected outcome, archived, expired) — see TASK-91 for how rejected outcomes are tracked. Delivery mechanism (email, in-app, something else) is an open decision for whoever picks this up to raise with Mike before implementing.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A posting with active pipeline involvement (favorited/applied/interview) that has had no new PipelineStep in 2-3 days triggers a notification to Mike
- [x] #2 The notification identifies which posting(s) are stale and how long since the last update
- [x] #3 Postings that have reached a terminal outcome (offered, rejected, archived, expired) do not trigger this notification
- [x] #4 A posting that receives a new PipelineStep resets its idle clock
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Delivery mechanism decided with Mike (2026-08-27): persistent in-app surface, not an ephemeral toast (JobRun's existing Turbo Stream pattern) or an external channel (no email/Slack/push infra exists in this app; would be new infrastructure, explicitly out of scope). Kept separate from the HumanTask inbox rather than added as a 5th HumanTask kind -- "idle 3 days" isn't an AI proposal awaiting approve/reject, it's a different concept, and folding it in would give HumanTask two unrelated meanings.

Plan:
1. UserJobPosting.idle scope + #last_pipeline_activity_at -- active pipeline involvement (favorited/applied/interview), no outcome in [offered, rejected], JobPosting.status not in [archived, expired], and no PipelineStep in IDLE_AFTER (3.days). NOT EXISTS against pipeline_steps rather than a stored idle-clock column -- every ACTIVE_STATUSES transition already logs a PipelineStep (record_status_event!/advance_pipeline_state!), so AC #4's "reset on new activity" falls out for free.
2. HomeController#assign_idle_followups, mirroring the existing @priority_inbox pattern exactly.
3. A new "Needs Follow-up" section on home/index.html.erb, same card layout as Priority Inbox, warning/amber color scheme (matches the stale-badge convention already used in the HumanTask inbox).
4. Model spec (scope + method) + a new home request spec.
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built as a persistent "Needs Follow-up" section on the home dashboard (not a toast/external channel -- decided with Mike). UserJobPosting.idle scope + #last_pipeline_activity_at, sorted most-neglected-first (matching HumanTask.stale's convention).

Two real bugs caught by testing against live dev data before shipping: (1) where.not(outcome: [...]) silently drops NULL-outcome rows since SQL's NOT IN never matches NULL -- outcome is nil for nearly every active posting, so the naive form matched almost nothing; rewritten as explicit "outcome IS NULL OR ..." (2) some real UserJobPosting rows (from the backfill importers, which write status directly) have zero PipelineStep ever, not just none recently -- last_pipeline_activity_at was returning nil and crashing distance_of_time_in_words in the view. Fixed with a COALESCE-to-created_at fallback shared between the scope's WHERE/ORDER BY and the instance method (LAST_ACTIVITY_SQL constant), so a freshly-imported row doesn't read as instantly idle.

Live-verified in dev: correctly surfaced 6 real stale applications (4mo/4mo/13d/12d/12d/12d), sorted oldest-first. 22 new/updated examples, 0 failures, rubocop + erb_lint + i18n-tasks clean.
<!-- SECTION:FINAL_SUMMARY:END -->
