---
id: TASK-61
title: Redirect back to referrer after marking a job posting Not Interested/Expired
status: Done
assignee: []
created_date: '2026-08-17 02:09'
updated_date: '2026-08-17 12:44'
labels: []
dependencies: []
modified_files:
  - app/controllers/application_controller.rb
  - app/controllers/job_postings_controller.rb
  - app/controllers/admin/pipeline_steps_controller.rb
  - app/views/job_postings/show.html.erb
  - spec/requests/job_postings_spec.rb
  - spec/requests/admin/pipeline_steps_spec.rb
priority: medium
type: enhancement
ordinal: 66000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Noted mid-session for later, not started. Currently Admin::PipelineStepsController#create always redirects to admin_job_posting_path(@job_posting) (or renders a turbo_stream card-removal for the index's ignore button). When marking a posting Not Interested or Expired from the show page, the user would rather land back wherever they came from (e.g. the job_postings index list they were triaging) than on the just-dismissed posting's own show page.
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
JobPostingsController#show captures request.referer via a new before_action, stripped down to a same-host relative path (ApplicationController#safe_return_path -- rejects any other host, so a crafted Referer can't smuggle an off-app redirect target). That path rides through the Not Interested/Expired button_to forms as a hidden return_to field. Admin::PipelineStepsController#respond_after_logging redirects there (re-validated server-side via a second helper, safe_return_path/safe_local_path, since the value round-trips through client-controlled form data) only for the ignore/expire events -- every other status button (Favorite/Apply/etc.) keeps the existing redirect to the posting's own page. Falls back to the posting's page when there's no referer, a cross-host referer, or a tampered/protocol-relative return_to.
<!-- SECTION:FINAL_SUMMARY:END -->
