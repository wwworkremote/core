---
id: TASK-35
title: 'Fix test-order-dependent flakiness in Charts::Data::Sources spec'
status: To Do
assignee: []
created_date: '2026-08-10 12:31'
updated_date: '2026-08-10 12:34'
labels: []
dependencies: []
references:
  - spec/requests/charts/data/sources_spec.rb
  - >-
    backlog/docs/docs/history/smoke-test-deployment.md/doc-1 -
    Smoke-Test-Deployment-and-Mandates.md
  - backlog/archive/tasks/task-8 - Audit-Post-Cleanup-Dead-File-Review.md
priority: low
type: bug
ordinal: 40000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Reproduced 2026-08-10 while committing regression-test documentation (task-32 validation pass) -- the pre-commit RSpec hook failed on:

```
spec/requests/charts/data/sources_spec.rb:7 # Charts::Data::Sources GET /charts/data/sources returns JSON data for source registration velocity
Failure/Error: expect(data.values.sum).to eq(1)
  expected: 1
       got: 3
```

**Root cause found, not just hypothesized:** `RAILS_ENV=test bin/rails runner 'puts Source.count; puts Source.pluck(:signature)'` showed 2 persisted rows already sitting in the test database: `"smoke_test_source"` and `"hackernews"`. These are written by `bin/verify_ingestion` (invoked by `bin/smoke`, which was run against `RAILS_ENV=test` as part of this same validation pass, and very likely by earlier sessions too) -- it runs a real ingestion sync against the test DB OUTSIDE of RSpec's transactional-fixture wrapper, so nothing rolls its writes back. `sources_spec.rb` creates 1 more Source and asserts the endpoint's total is 1, but with the 2 leftover rows already present the real total is 3. Confirmed by direct inspection, not inference -- this is not generic test-order flakiness, it's `bin/smoke`/`bin/verify_ingestion` polluting the shared test database on every run.

Was already flagged as a known instability in backlog doc-1 ("Smoke Test Deployment and Mandates", 2026-05-23), tracked under TASK-8, which was later archived (not completed) -- so this has likely been silently reproducing via the same mechanism for ~3 months without ever being root-caused.

Immediate workaround applied as part of this validation pass: manually deleted the 2 stray Source rows from the test DB so the suite is unpolluted going forward. That's a one-time cleanup, not a fix -- the next `bin/smoke`/`bin/verify_ingestion` run against RAILS_ENV=test will reintroduce the same rows.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 bin/verify_ingestion (or whatever it calls) either runs inside a transaction it rolls back, or explicitly cleans up the records it creates when run against RAILS_ENV=test, so it no longer leaves persistent Source/Document rows in the test database
- [ ] #2 spec/requests/charts/data/sources_spec.rb passes reliably standalone AND as part of the full suite immediately after running bin/smoke, not just on a freshly-cleaned test DB
- [ ] #3 Confirm whether other bin/smoke-adjacent scripts (bin/verify_llm.rb) have the same non-transactional-write-to-test-DB pattern and note the finding even if not all are fixed here
<!-- AC:END -->
