---
id: TASK-30
title: >-
  Schedule JobLifecycle::ExpirySweepJob -- 2,343 postings are stale and never
  expired
status: To Do
assignee: []
created_date: '2026-07-28 01:06'
labels: []
dependencies: []
priority: medium
ordinal: 29000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
ExpirySweepJob (queue_as :low, expires JobPosting rows older than 72h unless favorited/applied/interview/offered) is not referenced anywhere in config/recurring.yml -- it has never run on a schedule, only the :low queue having no worker (TASK-24, now fixed) would have blocked it even if something did enqueue it manually. Confirmed 2,343 job_postings are 72h+ old and still not status=expired as of 2026-07-27. Add a recurring.yml entry (daily seems reasonable given the 72h window) once TASK-24's :low worker group is live.
<!-- SECTION:DESCRIPTION:END -->
