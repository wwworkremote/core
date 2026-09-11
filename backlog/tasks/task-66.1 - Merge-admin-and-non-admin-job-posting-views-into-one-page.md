---
id: TASK-66.1
title: Merge admin and non-admin job posting views into one page
status: Done
assignee:
  - claude
created_date: '2026-08-17 23:13'
updated_date: '2026-08-17 23:32'
labels:
  - ux
  - job-postings
dependencies: []
parent_task_id: TASK-66
type: feature
ordinal: 72000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Part of TASK-66. Admin::JobPostingsController (app/controllers/admin/job_postings_controller.rb, app/views/admin/job_postings/show.html.erb) and JobPostingsController (app/controllers/job_postings_controller.rb, app/views/job_postings/show.html.erb) both render a page for the same JobPosting record, with diverging feature sets. Decision made with the user: retire the split into a single canonical view at the non-admin job_postings/:id URL.

Admin-only actions currently on the admin page -- Enrich Data (Scraper::Enricher), Synthesize (JobBoards::Categorizer), Purge/Restore, bulk operations, the pipeline activity/notes-with-attachments form (admin/job_postings/show.html.erb's "Activity" panel uses multipart file uploads via f.file_field :artifacts, which the non-admin notes form does not) -- need to move onto the unified page, gated by whatever authorization check currently gates Admin::ApplicationController (see its comment referencing `authenticate_admin`).

The semantic-matches turbo-frame feature (Admin::JobPostingsController#show's `frame == "semantic_matches"` branch, nearest_neighbors query, app/views/admin/job_postings/_semantic_matches.html.erb) is admin-only today and has no equivalent on the non-admin page -- decide whether it becomes part of the unified page or stays admin-gated.

Existing bookmarked/linked admin URLs (e.g. the browser extension's lead-to-posting links, any saved links in personal notes) should keep working -- a redirect from the old admin path to the unified path is likely needed rather than a hard 404.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A single job posting show page at job_postings/:id displays pipeline actions, Enrich Data, Synthesize/recategorize, Purge, Restore, and a similar-postings (semantic matches) panel
- [x] #2 Visiting the old admin/job_postings/:id URL for an existing posting redirects to the unified page rather than rendering a separate template or 404ing
- [x] #3 Existing request specs covering both the admin and non-admin show pages are updated to reflect the unified page and pass
- [x] #4 Every per-record action reachable on either show page today (favorite/apply/interview/offer/archive/ignore/expire, enrich, synthesize, purge, restore, check match, generate cover letter, notes, pipeline activity log with attachments, contacts, interview sessions/questions, tasks, similar postings) is reachable on the unified page
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Research findings (change the original framing)

- **No real two-tier auth exists.** `ApplicationController#authenticate_admin` is a
  `before_action` on the WHOLE app (every controller inherits it), single HTTP-Basic
  admin account, skipped entirely in dev/test. "Admin::" is a routing/code namespace
  left over from build history, not a separate permission tier. There is nothing to
  "gate by authorization" -- whoever can load any page can already do everything.
  Original AC #1 wording ("gated by authorization") was based on a wrong assumption;
  corrected.
- **The non-admin page is already the richer page.** job_postings/show.html.erb
  already renders pipeline actions, notes, AI match analysis, cover-letter
  generation, interview sessions/questions, contacts, tasks, company
  reputation/toxicity audit, recategorize (synthesize), AND a change-history panel
  (`@job_posting.versions.reverse.first(5)`, event/whodunnit/time only, no diff) --
  all via the *admin-namespaced* nested routes (admin_job_posting_pipeline_steps_path
  etc.), which already work from this non-admin-rendered page today. TASK-66.3
  (history panel) is therefore mostly done already; only needs "what changed" detail.
- **What's actually admin-only and missing from the non-admin page:** Enrich Data
  button, Purge/Restore buttons, the raw technical metadata block
  (signature/external_id/coordinates/published), and the Lead-badge link
  (`if @job_posting.leads.any? ... admin_lead_path`).
- **Bulk operations (purge/restore/delete selected) live only on the admin INDEX
  page** (checkbox multi-select + bulk_action_admin_job_postings_path), not any show
  page -- out of scope for a show-page merge. Original AC #4 mention removed.
- **`semantic_matches` (nearest-neighbor "similar jobs" turbo-frame) is orphaned but
  tested and working** -- controller branch + partial + a passing spec exist, but no
  UI anywhere links/frames to it (`frame: "semantic_matches"` param is never emitted
  by any view). Leaving it alone entirely (don't delete tested code, don't build new
  UI for it -- out of scope, flag separately if it should get a real entry point).

## Plan

1. app/views/job_postings/show.html.erb: add Enrich Data + Purge + Restore buttons
   (reuse the exact working pattern already used for "recategorize" on this same
   page -- `admin_job_posting_path`/`purge_admin_job_posting_path`/
   `restore_admin_job_posting_path`, no new backend routes/actions needed since
   these already work from non-admin-rendered pages). Add the Lead-badge link next
   to the title. Fold the raw technical metadata block into the existing "Details &
   history" sidebar card.
2. app/controllers/admin/job_postings_controller.rb#show: when `frame` param is
   absent, `redirect_to job_posting_path(@job_posting)` instead of rendering
   admin/job_postings/show. Leave the `frame == "semantic_matches"` branch
   untouched (still tested, still reachable via the direct param).
3. Delete app/views/admin/job_postings/show.html.erb (fully superseded).
   `_semantic_matches.html.erb` stays (still rendered by the untouched branch).
4. app/views/admin/job_postings/index.html.erb: change each row's
   `admin_job_posting_path(job)` link to `job_posting_path(job)` so browsing from
   the admin list lands directly on the unified page. Purge/Restore
   buttons on that index stay pointed at admin routes (unrelated to this merge).
5. Specs: update spec/requests/admin/job_postings_spec.rb's "GET
   /admin/job_postings/:id shows the job posting" to expect a redirect. Add specs to
   spec/requests/job_postings_spec.rb for the new Enrich Data/Purge/Restore buttons
   and Lead-badge link on the unified page, following that file's existing
   conventions (plain `JobPosting.create!`/`create(:job_posting)`, request specs
   under "GET /job_postings/:id").
6. Manual browser verification: load /job_postings/5817, exercise Enrich
   Data/Purge/Restore, confirm /admin/job_postings/5817 redirects, confirm nothing
   else on the page regressed (pipeline/notes/interview/contacts/tasks were already
   shared and should be unaffected).
7. Full RSpec suite + rubocop before considering done, per project convention.

Update after user review: user chose to also give semantic_matches a real entry point rather than leave it orphaned. Adding to the plan: (8) app/views/job_postings/show.html.erb -- add a lazily-loaded turbo_frame_tag "semantic_matches", src: admin_job_posting_path(@job_posting, frame: "semantic_matches"), loading: :lazy panel, reusing the existing already-tested Admin::JobPostingsController#show frame branch, no new route/controller code needed. (9) app/views/admin/job_postings/_semantic_matches.html.erb -- repoint its two admin_job_posting_path links (per-match link, Full view link) to job_posting_path so clicking through lands directly on the unified page instead of bouncing through the new redirect.
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Merged the admin and non-admin job posting show pages into one canonical view at job_postings/:id.

**What changed:**
- app/views/job_postings/show.html.erb: added the pieces that were admin-only -- Enrich Data button, Purge/Restore buttons (guarded by may_purge?/may_restore?, Purge has a turbo_confirm), a Lead-badge link next to the title, a raw technical-metadata block (signature/external_id/coordinates/published) folded into the existing Details & History card, and (per user request during review) a lazily-loaded "Similar Postings" turbo-frame panel reusing the existing semantic_matches endpoint.
- app/controllers/admin/job_postings_controller.rb#show: redirects to job_posting_path when no `frame` param is present, instead of rendering its own template. The `frame == "semantic_matches"` branch is untouched (still directly reachable, now also embedded live on the unified page).
- Deleted app/views/admin/job_postings/show.html.erb (fully superseded).
- Repointed every direct link to the old admin show page (admin/job_postings/index row links, admin/domains/show, admin/leads/show, admin/companies/show, and the semantic_matches partial's own links) at job_posting_path directly, avoiding an unnecessary redirect hop.
- Fixed 3 controllers (admin/pipeline_steps_controller.rb, admin/contacts_controller.rb, admin/job_postings_controller.rb#update) whose redirect targets pointed at the now-redirecting admin_job_posting_path -- retargeted to job_posting_path directly (a real regression caught by the full suite, not just the merge's own new specs).
- config/locales/en.yml: added i18n keys for the new buttons/labels, matching this page's existing i18n convention (the admin page had used plain strings).

**Scope corrections made during research/planning** (recorded and user-confirmed before implementation): there is no real two-tier auth to "gate" -- authenticate_admin covers the whole app equally, single account, skipped in dev/test. Bulk operations (purge/restore/delete selected) stayed on the admin index page -- an index-page concern, not part of a show-page merge. semantic_matches was initially going to be left alone as orphaned-but-tested; user asked to give it a real entry point instead, which was added.

**Tests:** spec/requests/admin/job_postings_spec.rb updated (show now expects a redirect); spec/requests/job_postings_spec.rb gained specs for Enrich Data, Purge/Restore visibility by status, the Lead badge, and the similar-postings frame; spec/requests/contacts_spec.rb and spec/requests/admin/pipeline_steps_spec.rb updated for the corrected redirect targets. Full suite: 571 examples, 0 failures. Rubocop and erb_lint clean (one pre-existing, unrelated erb_lint warning on the livereload script in application.html.erb, not touched by this task). Manually verified in a real browser: unified page renders all actions, /admin/job_postings/:id redirects correctly, Enrich Data runs end-to-end with a flash notice, similar-postings frame loads lazily on scroll and populates real results.

**Follow-ups this unblocks:** TASK-66.2 (cover letter display), TASK-66.3 (change-history detail -- the panel already exists on this page, just needs the "what changed" diff), TASK-66.4 (Q&A feature) can now all target this single page.
<!-- SECTION:FINAL_SUMMARY:END -->
