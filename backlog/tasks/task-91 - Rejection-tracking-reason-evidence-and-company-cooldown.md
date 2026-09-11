---
id: TASK-91
title: 'Rejection tracking: reason, evidence, and company cooldown'
status: Done
assignee: []
created_date: '2026-08-26 23:09'
updated_date: '2026-08-27 14:29'
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

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Both subtasks complete. TASK-91.1: decline reason + rejection-email/screenshot attachment captured at the moment of marking rejected, with Clear now purging both. TASK-91.2: per-company 6-month decline cooldown, auto-started on reject, backfillable directly (used to record the task's own Cengage example), surfaced everywhere Mike evaluates a company (its own page, the companies listing, and the job posting page itself). Found and fixed a real pre-existing bug along the way: Company_record silently returned nil for any posting with a resolved company_id.
<!-- SECTION:FINAL_SUMMARY:END -->
