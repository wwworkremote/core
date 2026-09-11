---
id: TASK-51
title: >-
  Fix ignore button on job_postings index: turbo_stream request got a hard
  redirect
status: Done
assignee: []
created_date: '2026-08-16 15:07'
updated_date: '2026-08-16 15:12'
labels: []
dependencies: []
references:
  - app/controllers/admin/pipeline_steps_controller.rb
  - app/views/job_postings/index.html.erb
  - spec/requests/admin/pipeline_steps_spec.rb
priority: high
type: bug
ordinal: 57000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
User-reported: "the ignore filter isn't being respected" on /job_postings. The query-level exclusion (`where.not(status: %w[ignored purged expired])`, job_postings_controller.rb) was never actually broken -- confirmed live against 135 real ignored postings in dev. The real bug: the ignore button on job_postings/index.html.erb:105 submits with `data: { turbo_stream: true }`, but Admin::PipelineStepsController#create unconditionally did `redirect_to admin_job_posting_path(@job_posting)` -- a hard redirect to the admin show page, never a turbo_stream response. Clicking ignore navigated the user away entirely instead of just removing the card in place; the underlying AASM state change did persist correctly, so this was a response-format bug, not a data bug.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Wrote a failing regression spec first (POST with `as: :turbo_stream`, asserting turbo_stream media type + a `remove` targeting the posting's dom_id) -- confirmed red against the unmodified controller.

First fix attempt used `respond_to { |format| format.turbo_stream { ... }; format.html { redirect_to ... } }` -- this passed the new spec but broke the full suite (`spec/system/user_pipeline_flow_spec.rb`, "Activity logged" never appeared). Root cause: Turbo Drive sends `Accept: text/vnd.turbo-stream.html` on every form submission by default, not just ones with a `data-turbo-stream` flag -- `format.turbo_stream` on this shared action hijacked every OTHER status button (Favorite, Apply, ...) across every view that uses it (admin/job_postings/show, public job_postings/show, admin/companies/show), not just the index's ignore button.

Corrected fix: dropped content-negotiation entirely in favor of an explicit `remove_card` param sent only by job_postings/index.html.erb's ignore button (`params: { status: 'ignore', remove_card: true }`); the controller checks `params[:remove_card] == "true"` directly rather than relying on Accept-header format detection. Added a second regression spec proving a plain "favorite" transition still redirects with the flash notice even when the request accepts turbo_stream (the exact scenario that broke the system spec) -- this is the coverage that would have caught the first attempt's mistake, added per explicit ask not to leave this on assumptions.

Verified: full non-live suite green (490 examples, 0 failures, including the system spec), RuboCop and erb_lint clean on every touched file.
<!-- SECTION:FINAL_SUMMARY:END -->
