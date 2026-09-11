---
id: TASK-66.3
title: Show job posting change history on the job posting page
status: Done
assignee:
  - claude
created_date: '2026-08-17 23:13'
updated_date: '2026-08-18 02:51'
labels:
  - ux
  - job-postings
dependencies:
  - TASK-66.1
parent_task_id: TASK-66
type: feature
ordinal: 74000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Part of TASK-66, targets the unified page from the view-merge subtask. JobPosting already declares `has_paper_trail` (app/models/job_posting.rb:14) and PaperTrail is actively recording versions on every save -- confirmed non-empty `versions` table in dev, including changes made by JobBoards::Reformatter/JobPostingReformatJob (the AI description-reformatting flow). There is currently no view anywhere that renders `job_posting.versions`.

Add a change-history panel to the job posting page showing what changed, when, and (where available) what triggered it -- e.g. a reformat job run, a manual edit, an enrichment pass. PaperTrail's `whodunnit` is likely blank for system/job-triggered changes (no request context), so the display should degrade gracefully to "system" or the job/process name rather than a blank attribution, using whatever PaperTrail metadata (event type, object_changes) is actually available rather than assuming a user is always behind each version.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Job posting page shows a chronological list of recorded versions (create/update events) with timestamps
- [x] #2 Each entry shows what changed in human-readable form (not raw serialized diff), using PaperTrail's object_changes
- [x] #3 Versions with no whodunnit (system/job-triggered changes) display sensibly rather than blank or erroring
- [x] #4 History is reachable without leaving the job posting page (inline panel, tab, or modal -- not a separate top-level route)
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
The history panel already existed (event/who/time, one line per version) -- this task made it actually show what changed, and fixed a real infrastructure bug found along the way.

**Root cause found:** `versions` had no `object_changes` column, and PaperTrail::Version#changeset unconditionally returns nil without one (it does not derive a diff from `object` after the fact, contrary to what the task description assumed going in). Deeper than that: even after adding the column, `changeset` still silently returned empty for every version, because Rails' safe YAML loader (`ActiveRecord.yaml_column_permitted_classes`, default `[Symbol]`) rejects `ActiveSupport::TimeWithZone` -- present in literally every version's `updated_at`/`created_at` -- so deserializing `object`/`object_changes` has been silently broken for this app since `has_paper_trail` was first added, just never surfaced because nothing had read those columns before.

**What changed:**
- Migration: `versions.object_changes` (text). PaperTrail auto-populates it for all new versions once the column exists -- no other config needed for the write path.
- config/initializers/paper_trail.rb (new): extends `ActiveRecord.yaml_column_permitted_classes` with Time/Date/DateTime/TimeWithZone/TimeZone/BigDecimal, fixing deserialization for both `object` and `object_changes` app-wide, not just this feature.
- app/helpers/job_postings_helper.rb: `version_changes_summary(version)` -- turns a changeset into `"Field: old → new"` lines, drops updated_at/created_at (pure noise, not "what changed"), and summarizes non-scalar values (hashes, arrays) as "changed" rather than dumping raw content (job_posting.data is a jsonb blob; job_posting.body can be tens of KB of scraped text -- neither belongs inline in a change-history list). Returns nil (not an empty array) when there's nothing to show, so the view can distinguish "no detail captured" (historical, pre-migration versions) from "nothing changed."
- app/views/job_postings/show.html.erb: renders the summary as a bullet list under each history entry when present; added `.includes(:item)` to the versions query, required after Bullet's N+1 detector caught `changeset`'s internal `item.class` access looping per version.

**Tests:** spec/helpers/job_postings_helper_spec.rb gained 5 examples for `#version_changes_summary` (real diff, nil-changeset, empty-changeset, non-scalar summarization). spec/requests/job_postings_spec.rb gained one covering the rendered "Field: old → new" line. Full suite: 579 examples, 0 failures. Rubocop and erb_lint clean.

**Manual verification:** live dev DB, job posting 5817 -- triggered a real title update, restarted the dev Puma server (required: Rails initializers only run at boot, not on autoload/reload, so the YAML-permitted-classes fix didn't apply until restart), confirmed in the browser that the new version shows "Title: [old] → [new]", a prior jsonb `data` change shows "Data: changed → changed" (no raw dump), and pre-migration historical versions still show cleanly with no detail line and no error.

**Follow-up still open on TASK-66:** TASK-66.4 (Q&A generator) is the only remaining subtask.
<!-- SECTION:FINAL_SUMMARY:END -->
