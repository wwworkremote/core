---
id: TASK-56
title: Investigate recurring test-order-dependent flakiness across spec files
status: Done
assignee: []
created_date: '2026-08-16 18:16'
updated_date: '2026-08-19 14:58'
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

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Root cause found already fixed by unrelated work, verified live before closing (per backlog-audit skill).

Commit ada10848 ("Fix ActiveJob::Base.queue_adapter test pollution at the source", 2026-08-17, two days after this task was filed) added a `config.after` teardown in `spec/rails_helper.rb` restoring `ActiveJob::Base.queue_adapter = :solid_queue` after every example, because several specs set `queue_adapter = :test` with no teardown and it leaked into whichever spec ran next in the same process — this is a textbook explanation for the "ContentEnrichmentJob not enqueued" failure this task reported in `spec/system/job_ingestion_flow_spec.rb` (a job-enqueue assertion failing depending on which adapter was active, which depends on run order).

Live-verified rather than trusting git-archaeology alone: ran the full suite three times with different random seeds (`--seed 12345`, `--seed 777`, `--seed 4242`, the latter including `packages/ingestion/spec`) — 632-867 examples, 0 failures each time, including both previously-flaky files (`spec/system/job_ingestion_flow_spec.rb`, `spec/services/job_boards/reformatter_spec.rb`). ApiGuard circuit-breaker WARN logs (the other suspect this task named) appear routinely during normal passing runs — they're expected test noise from circuit-breaker-behavior specs, not evidence of leaked state on their own.

Caveat: order-dependent flakiness can't be proven fully absent, only unreproduced despite reasonable effort (3 full-suite random-seed runs). If it recurs, the queue_adapter leak is now closed off as a cause, so look elsewhere (WebMock stub state, class-level memoization) first.
<!-- SECTION:FINAL_SUMMARY:END -->
