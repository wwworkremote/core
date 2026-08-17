---
id: TASK-61
title: Redirect back to referrer after marking a job posting Not Interested/Expired
status: To Do
assignee: []
created_date: '2026-08-17 02:09'
labels: []
dependencies: []
priority: medium
type: enhancement
ordinal: 66000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Noted mid-session for later, not started. Currently Admin::PipelineStepsController#create always redirects to admin_job_posting_path(@job_posting) (or renders a turbo_stream card-removal for the index's ignore button). When marking a posting Not Interested or Expired from the show page, the user would rather land back wherever they came from (e.g. the job_postings index list they were triaging) than on the just-dismissed posting's own show page.
<!-- SECTION:DESCRIPTION:END -->
