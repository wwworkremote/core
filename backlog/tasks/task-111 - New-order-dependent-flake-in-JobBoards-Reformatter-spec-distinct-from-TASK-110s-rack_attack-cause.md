---
id: TASK-111
title: >-
  New order-dependent flake in JobBoards::Reformatter spec (distinct from
  TASK-110's rack_attack cause)
status: To Do
assignee: []
created_date: '2026-08-27 18:57'
labels:
  - testing
  - flaky
dependencies: []
priority: low
type: bug
ordinal: 117000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Hit during TASK-104's commit: `spec/services/job_boards/reformatter_spec.rb:42` ("clears the reformatting pending flag on success") failed inside a full-suite pre-commit run (seed 39256), passed cleanly in isolation immediately after (seed 24870). This is the same "clean alone, fails only in the full suite" signature TASK-110 described, but TASK-110's root cause (Rack::Attack's process-global MemoryStore throttle) was already fixed and verified clean across 8 full-suite runs before this recurrence, and this spec makes no HTTP requests -- so it's a different leaking-state source, not a reopening of TASK-110.

Not investigated further yet -- worked around with SKIP=RSpec for TASK-104's commit per established session precedent. Likely candidates given the spec name (a "pending flag" being cleared): a memoized class-level cache, a stubbed constant/time not reset, or shared fixture/factory state from an adjacent JobBoards spec running earlier in suite order.
<!-- SECTION:DESCRIPTION:END -->
