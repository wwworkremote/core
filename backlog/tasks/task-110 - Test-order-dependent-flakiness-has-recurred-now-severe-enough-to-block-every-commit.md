---
id: TASK-110
title: >-
  Test-order-dependent flakiness has recurred, now severe enough to block every
  commit
status: Done
assignee: []
created_date: '2026-08-27 17:56'
updated_date: '2026-08-27 18:42'
labels:
  - testing
  - flaky
dependencies: []
references:
  - TASK-56
modified_files:
  - config/environments/test.rb
  - config/initializers/rack_attack.rb
  - spec/requests/rack_attack_test_isolation_spec.rb
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
- [x] #1 Root cause identified via reproduction (repeated full-suite runs with different --seed values until a failure recurs, then bisect which earlier spec's state pollution causes it) -- not just a plausible theory
- [x] #2 The pre-commit RSpec hook passes reliably across at least 5 consecutive full-suite runs with different random seeds after the fix
- [x] #3 If the fix can't be made repo-wide quickly, at minimum the specific specs observed failing this session (legacy_company_access_spec.rb, the api/v0/application_* cluster) are confirmed clean under the fix
- [x] #4 References TASK-56 as prior related work -- same problem class, different (not yet identified) cause
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Root cause: Rack::Attack, not the queue_adapter/WebMock/memoization classes of leak TASK-56 already ruled out. `config/initializers/rack_attack.rb` explicitly points its throttle store at a bare `ActiveSupport::Cache::MemoryStore.new`, not `Rails.cache` -- so rails_helper's global `config.before { Rails.cache.clear }` never touches it. That store is process-global for the life of one `rspec` invocation, and the "api/ip" throttle (`limit: 60, period: 1.minute`) counts every request to any `/api/*` path from the test-client IP (127.0.0.1) across every request spec in the run, not per-example. A full suite fires far more than 60 `/api/*` requests within any 60-second window, so the throttle trips mid-suite at a point that depends entirely on random spec order and timing, and any spec whose request lands after the trip gets a silent 429 instead of executing -- exactly the "passes clean in isolation, fails only as part of the full suite" signature reported for the api/v0/application_* cluster. Reproduced directly: `--seed 5` failed `spec/requests/api/leads_spec.rb:44` (`Lead.where(url: url).count` expected 1 got 0) with `[RackAttack] Throttled 127.0.0.1 on /api/leads` logged immediately before it; `--seed 2026` failed `spec/requests/api/job_postings_spec.rb:110` (`POST /api/job_postings/:id/enrich`) the same way. Both are `/api/*` request specs, matching the throttled prefix exactly.

Fix: `config.after_initialize { Rack::Attack.enabled = false }` in `config/environments/test.rb` -- rate limiting isn't something app/request specs are testing, so it's disabled there the same way any other non-production concern would be, rather than resetting the store per-example (which would still leave the throttle live and able to 429 a spec that's deliberately testing high request volume). Also corrected a stale comment in `config/initializers/rack_attack.rb` that claimed the store was Rails.cache/Solid Cache when the very next line already overrides it with a plain MemoryStore.

New regression spec `spec/requests/rack_attack_test_isolation_spec.rb`: fires 62 requests at `GET /api/v0/geo` in one example and asserts the response is never 429. Confirmed red against the pre-fix code (`expected the response not to have status code :too_many_requests (429) but it did`), green after the fix.

Verification: full suite (`bin/rspec-precommit`, i.e. `bundle exec rspec --fail-fast spec packages/ingestion/spec`) run clean 7+ times post-fix with distinct random seeds, including re-runs of both seeds that reproduced real failures pre-fix (5 and 2026, now 0 failures / 1147 examples each) and 5 additional back-to-back runs with fresh random seeds (22430, 32506, 21449, 17319, 16272), all 1147 examples / 0 failures. legacy_company_access_spec.rb and the full api/v0/application_* cluster also pass explicitly (28 examples, 0 failures) and inside every full-suite run above.

Note: the legacy_company_access_spec.rb failure mentioned in the task description wasn't independently reproduced this session (it's a pure model spec with no HTTP requests, so it can't be explained by the Rack::Attack leak). Given it hasn't recurred across 7+ clean full-suite runs post-fix and the queue_adapter leak (TASK-56) is confirmed still fixed, it's most likely attributable to a stray already-running `rspec` process found holding a lock on the shared test database during this session (killed before verification) rather than a second distinct code bug -- flagging this rather than claiming it's proven fixed.
<!-- SECTION:FINAL_SUMMARY:END -->
