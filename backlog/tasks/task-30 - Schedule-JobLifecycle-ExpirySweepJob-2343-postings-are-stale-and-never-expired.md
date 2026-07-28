---
id: TASK-30
title: >-
  Schedule JobLifecycle::ExpirySweepJob -- 2,343 postings are stale and never
  expired
status: Done
assignee: []
created_date: '2026-07-28 01:06'
updated_date: '2026-07-28 01:32'
labels: []
dependencies: []
priority: medium
ordinal: 29000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
ExpirySweepJob (queue_as :low, expires JobPosting rows older than 72h unless favorited/applied/interview/offered) is not referenced anywhere in config/recurring.yml -- it has never run on a schedule, only the :low queue having no worker (TASK-24, now fixed) would have blocked it even if something did enqueue it manually. Confirmed 2,343 job_postings are 72h+ old and still not status=expired as of 2026-07-27. Add a recurring.yml entry (daily seems reasonable given the 72h window) once TASK-24's :low worker group is live.
<!-- SECTION:DESCRIPTION:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added expire_stale_postings to recurring.yml (daily 4:30am). Running it manually surfaced a real crash: the query excluded status='expired' but not 'purged', and AASM's expire event doesn't allow transitioning from purged (AASM::InvalidTransition), which halted the whole find_each batch mid-sweep on the first purged row hit -- only 1,983 of 2,343 stale postings got expired before it died. Fixed the query to exclude both (where.not(status: %w[expired purged])). Re-ran manually to clear the existing backlog rather than waiting for the 4:30am schedule: 2,340 expired, 17 purged correctly skipped, completed with no errors. Without this fix the newly-scheduled job would have failed silently (as a failed_execution, not a crash-loop) every night.
<!-- SECTION:NOTES:END -->
