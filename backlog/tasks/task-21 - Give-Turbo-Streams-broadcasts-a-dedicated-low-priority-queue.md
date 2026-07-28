---
id: TASK-21
title: Give Turbo Streams broadcasts a dedicated low-priority queue
status: Done
assignee: []
created_date: '2026-07-27 21:57'
updated_date: '2026-07-28 00:16'
labels: []
dependencies: []
priority: high
ordinal: 20000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Turbo::Streams::ActionBroadcastJob (fired 2x per JobPosting save, plus Source/DiscoveryLink) shares the plain 'default' queue with heavyweight LLM/geocoding/Playwright jobs. With only 3 default-queue threads in dev, cheap high-frequency UI-push jobs queue up behind slow work with zero isolation -- this is what produced a 4,700+ job backlog of stale broadcasts (cleaned up 2026-07-27). Add Turbo::Streams::ActionBroadcastJob.queue_as :broadcasts in an initializer and a small dedicated worker group in config/queue.yml so cheap pushes can never head-of-line-block behind heavy work again.
<!-- SECTION:DESCRIPTION:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added config/initializers/turbo_broadcast_queue.rb (Turbo::Streams::ActionBroadcastJob.queue_as :broadcasts) and a dedicated 'broadcasts' worker group in config/queue.yml (1 thread default/prod, 2 dev). Verified: Turbo::Streams::ActionBroadcastJob.new.queue_name now returns 'broadcasts'; restarted the jobs service and confirmed solid_queue_processes shows 'broadcasts' as a live registered worker group alongside heavy/light/default, no boot errors.
<!-- SECTION:NOTES:END -->
