---
id: TASK-110
title: >-
  Test-order-dependent flakiness has recurred, now severe enough to block every
  commit
status: To Do
assignee: []
created_date: '2026-08-27 17:56'
labels:
  - testing
  - flaky
dependencies: []
references:
  - TASK-56
priority: high
type: bug
ordinal: 50
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-56 closed 2026-08-19 on a specific root cause (ActiveJob::Base.queue_adapter leaking between specs, fixed by commit ada10848) and verified clean with 3 full-suite random-seed runs at the time. Its own final summary explicitly caveated: "if it recurs, the queue_adapter leak is now closed off as a cause, so look elsewhere (WebMock stub state, class-level memoization) first." It has recurred.

2026-08-27: the pre-commit hook (overcommit, runs the full RSpec suite) failed on 3 separate commit attempts in one session, each on a different spec, each confirmed passing cleanly when run alone immediately after:
- spec/models/concerns/job_posting/legacy_company_access_spec.rb (5 examples, 0 failures in isolation)
- Two earlier full-suite runs the same day surfaced ~20 failures concentrated in api/v0/application_* request specs, all passing cleanly in isolation

This is now materially worse than TASK-56's original scope: it blocked every single commit attempt that day regardless of what was actually being committed, not just an occasional flaky run. Commits landed only after getting explicit approval to skip the RSpec pre-commit hook (SKIP=RSpec) for that session -- not a fix, a workaround that shouldn't need to become the norm for landing any commit in this repo.

Root cause not yet investigated this time. The queue_adapter leak is already ruled out (fixed and still in place). Other shared/leaked global state remains suspect: WebMock stub registration, class-level memoization (several services use ||= caching), Rails.cache state, or SolidQueue/ApiGuard circuit-breaker state bleeding across spec files depending on run order.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Root cause identified via reproduction (repeated full-suite runs with different --seed values until a failure recurs, then bisect which earlier spec's state pollution causes it) -- not just a plausible theory
- [ ] #2 The pre-commit RSpec hook passes reliably across at least 5 consecutive full-suite runs with different random seeds after the fix
- [ ] #3 If the fix can't be made repo-wide quickly, at minimum the specific specs observed failing this session (legacy_company_access_spec.rb, the api/v0/application_* cluster) are confirmed clean under the fix
- [ ] #4 References TASK-56 as prior related work -- same problem class, different (not yet identified) cause
<!-- AC:END -->
