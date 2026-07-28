---
id: TASK-21
title: Give Turbo Streams broadcasts a dedicated low-priority queue
status: To Do
assignee: []
created_date: '2026-07-27 21:57'
labels: []
dependencies: []
priority: high
ordinal: 20000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Turbo::Streams::ActionBroadcastJob (fired 2x per JobPosting save, plus Source/DiscoveryLink) shares the plain 'default' queue with heavyweight LLM/geocoding/Playwright jobs. With only 3 default-queue threads in dev, cheap high-frequency UI-push jobs queue up behind slow work with zero isolation -- this is what produced a 4,700+ job backlog of stale broadcasts (cleaned up 2026-07-27). Add Turbo::Streams::ActionBroadcastJob.queue_as :broadcasts in an initializer and a small dedicated worker group in config/queue.yml so cheap pushes can never head-of-line-block behind heavy work again.
<!-- SECTION:DESCRIPTION:END -->
