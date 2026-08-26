---
id: TASK-93
title: Notify Mike when a pipeline item has been idle 2-3 days
status: To Do
assignee: []
created_date: '2026-08-26 23:10'
labels: []
dependencies: []
priority: medium
type: feature
ordinal: 108000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Leads/applications that go quiet risk being forgotten as the pipeline grows. Mike wants to be notified when a posting he's actively tracking hasn't had any pipeline activity in 2-3 days, so following up doesn't silently fall through. "Active" means it hasn't reached a terminal state (offered, rejected outcome, archived, expired) — see TASK-91 for how rejected outcomes are tracked. Delivery mechanism (email, in-app, something else) is an open decision for whoever picks this up to raise with Mike before implementing.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A posting with active pipeline involvement (favorited/applied/interview) that has had no new PipelineStep in 2-3 days triggers a notification to Mike
- [ ] #2 The notification identifies which posting(s) are stale and how long since the last update
- [ ] #3 Postings that have reached a terminal outcome (offered, rejected, archived, expired) do not trigger this notification
- [ ] #4 A posting that receives a new PipelineStep resets its idle clock
<!-- AC:END -->
