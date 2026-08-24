---
id: TASK-86
title: Job posting show page is read-only and Apply on Site records nothing
status: To Do
assignee: []
created_date: '2026-08-24 19:02'
labels: []
dependencies: []
priority: high
type: feature
ordinal: 99000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Two gaps found together on `/job_postings/5852`. Both are "never built", not "broken".

## 1. There is no way to edit a posting

`bin/rails routes` for job_postings exposes only:

- `job_postings#index`, `#show`, `#reformat` (POST)
- `admin/job_postings#show`, `#purge`, `#restore`, `#bulk_action`

**No `edit`, no `PATCH /job_postings/:id`, no `update` action anywhere.** `UserJobPosting` has a PATCH but its permitted params are `[:notes]` only, and it deliberately excludes `:status` so AASM guards can't be bypassed.

Consequence: a typo in scraped data is permanent. Posting **#5034 is titled `taff Software Engineer`** — a leading character eaten during extraction, unfixable through the UI. (Checked: this is the only such row, so a per-row edit is the right fix, not a parser hunt.)

Scraped data is dirty by nature — company_name is blank on **141 tracked rows**. Hand-correction needs to be a normal affordance, matching the "power user, admin and browsing merged" design of this app.

## 2. "Apply on Site" is a bare outbound link

`app/views/job_postings/show.html.erb:82` — it is `link_to outbound_link_path(...)`, `target: "_blank"`. It records the outbound click and **changes no status at all**. Neither does the sibling "Open source listing" button, which appends `?wwr_id=` for the extension to pick up on submit.

Mike's read: it should favorite, and should mark applied.

**Favorite on click: yes, unambiguously.** Clicking through to an employer's site is intent, and `favorite` is legal from `none`.

**Applied on click: recommend not automatically, for the reason already established in this codebase.** `bin/import_linkedin_tracker` deliberately records LinkedIn's `clicked_apply` as *favorited*, not applied, because leaving for the employer's site is not evidence of finishing an application. Auto-applying here reintroduces exactly the funnel inflation that decision avoided — and the funnel is the thing being rebuilt right now (TASK-81).

Suggested shape: favorite immediately on click, then surface a visible "Did you finish applying?" affordance on return, so `applied` stays a fact Mike asserts rather than one inferred from a click. The extension's Greenhouse submit capture (TASK-78) already sets `applied` from real evidence where it can.

## Acceptance criteria

- A posting's title, company_name, and location are editable from the UI
- Editing a posting cannot change `status` directly — transitions still go through `record_status_event!`
- #5034's title is correctable through that UI
- "Apply on Site" favorites the posting on click
- "Apply on Site" does NOT silently mark applied; applied requires an explicit confirmation or real submit evidence
- The outbound click is still recorded as it is today
- Both JobPosting and UserJobPosting stay consistent after any status change (TASK-82)
<!-- SECTION:DESCRIPTION:END -->
