---
id: TASK-56
title: Investigate recurring test-order-dependent flakiness across spec files
status: To Do
assignee: []
created_date: '2026-08-16 18:16'
labels: []
dependencies: []
priority: medium
type: bug
ordinal: 62000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Hit order-dependent full-suite failures 3x in one session, each time passing 0-failures in isolation: `spec/system/job_ingestion_flow_spec.rb` (ContentEnrichmentJob not enqueued), and all 5 examples of `spec/services/job_boards/reformatter_spec.rb` failing together under one random seed, passing clean under another. TASK-35 already fixed one instance of this class of bug (`Charts::Data::Sources` spec) via isolating test-order dependence -- this looks like the same systemic pattern recurring in new places (likely shared/leaked global state -- ENV, class-level memoization, a stubbed singleton, or WebMock/ApiGuard circuit-breaker state -- bleeding between spec files depending on run order), not three unrelated one-off flakes.

Reproduce by running the full suite (`bundle exec rspec spec packages/ingestion/spec`) repeatedly with different random seeds (`--seed N`) until a failure recurs, then bisect which earlier-run spec's state pollution causes it. Both known failure signatures should be checked: the ApiGuard circuit-breaker WARN logs seen right before each failure are a plausible shared-state suspect worth checking first.
<!-- SECTION:DESCRIPTION:END -->
