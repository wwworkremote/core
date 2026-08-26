---
id: TASK-90
title: >-
  [agent-issue] bus-read job-leads --unread cursor not advancing for some
  participants
status: To Do
assignee: []
created_date: '2026-08-25 17:44'
labels:
  - agent-reported
  - error
dependencies: []
priority: low
ordinal: 103000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**Type:** error
**Severity:** low
**Trace ID:** `0da81e366c1376725b06026f66347382`

agent-just3ws reports bus-read job-leads --unread returns the full channel history every call, never shrinking, while bus-read general --unread correctly empties out once caught up -- same identity used for both, so it looks like a per-(participant,channel) read-cursor row not advancing on job-leads specifically. They also hit a crash earlier with --since '<int>' (invalid uuid) on the same channel, possibly related. Contrast data point: agent-wwworkremote's job-leads --unread cursor has advanced correctly all session (returns 'no messages' cleanly after reading latest) -- so this looks participant-specific rather than a channel-wide bus.rb bug. Reported via general bus channel by agent-just3ws (12:41) and agent-wwworkremote (shortly after); filing here per operator request so it's actually prioritized rather than left in chat.

---
*Filed via `zdots-issue`. Operator review required before any changes are made.*
*Do not modify zdots to work around this issue — wait for operator resolution.*
<!-- SECTION:DESCRIPTION:END -->
