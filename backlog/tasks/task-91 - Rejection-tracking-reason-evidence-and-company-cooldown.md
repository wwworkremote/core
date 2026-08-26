---
id: TASK-91
title: 'Rejection tracking: reason, evidence, and company cooldown'
status: To Do
assignee: []
created_date: '2026-08-26 23:09'
labels: []
dependencies: []
priority: medium
type: feature
ordinal: 104000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Mike wants to record why an application was rejected/declined, keep the rejection email as evidence, and stop re-evaluating a company's postings for a cooldown period after it declines him — evaluating a company he was just rejected by is consistently a waste of his time.

The app already has the right foundation for the first half of this: `UserJobPosting#outcome` (plus `outcome_at`/`outcome_source`), shown on the job posting page, deliberately modeled *separate* from pipeline status. The existing code comment explains why: "'interviewed then declined' and 'applied and silent' are different facts the status column can't hold." There's already a "Mark Rejected" / "Clear" control at app/views/job_postings/show.html.erb (~line 331-353). This work extends that existing outcome flow — it does not need a new status value, and does not depend on TASK-82 (the JobPosting.status vs UserJobPosting.status drift bug) since outcome is already correctly separated from status.

Concrete real example: job posting #253 (Cengage, "Principal Software Engineer") — applied, declined the next day. That decline should be attachable with a reason and the rejection email, and should start a cooldown on Cengage.

Split into two subtasks: (1) decline reason + email attachment on the outcome record itself, (2) deriving and surfacing a per-company cooldown from those decline events.
<!-- SECTION:DESCRIPTION:END -->
