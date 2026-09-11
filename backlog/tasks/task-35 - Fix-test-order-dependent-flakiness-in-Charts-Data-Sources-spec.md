---
id: TASK-35
title: 'Fix test-order-dependent flakiness in Charts::Data::Sources spec'
status: Done
assignee: []
created_date: '2026-08-10 12:31'
updated_date: '2026-08-16 12:56'
labels: []
dependencies: []
references:
  - spec/requests/charts/data/sources_spec.rb
  - >-
    backlog/docs/docs/history/smoke-test-deployment.md/doc-1 -
    Smoke-Test-Deployment-and-Mandates.md
  - backlog/archive/tasks/task-8 - Audit-Post-Cleanup-Dead-File-Review.md
priority: medium
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
- [x] #1 bin/verify_ingestion (or whatever it calls) either runs inside a transaction it rolls back, or explicitly cleans up the records it creates when run against RAILS_ENV=test, so it no longer leaves persistent Source/Document rows in the test database
- [x] #2 spec/requests/charts/data/sources_spec.rb passes reliably standalone AND as part of the full suite immediately after running bin/smoke, not just on a freshly-cleaned test DB
- [x] #3 Confirm whether other bin/smoke-adjacent scripts (bin/verify_llm.rb) have the same non-transactional-write-to-test-DB pattern and note the finding even if not all are fixed here
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Same pattern reproduced independently 2026-08-16: running `RAILS_ENV=test bundle exec rake quality` (to verify a CI fix) wrote a real, non-transactional SystemInsight row into the local wwworkremote_test database via Quality::InsightIngester, which then broke spec/jobs/quality/insight_embedding_job_spec.rb (expected 1 enqueued job, got 2) on every subsequent run until manually cleared with SystemInsight.delete_all. This is the same root cause class this task already names (a non-transactional script writing real rows to RAILS_ENV=test outside RSpec's fixture rollback) but a different offending script -- `rake quality`'s ingesters, not bin/verify_ingestion. Worth broadening AC #3's scope: any script/rake task that can run under RAILS_ENV=test and performs real (non-request-spec, non-transactional) DB writes is a candidate for this same failure mode, not just the bin/smoke-adjacent ones.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Root cause: two separate scripts were writing real, non-transactional rows into whatever DB `RAILS_ENV=test` pointed at, and both fixes generalize (they close off the whole failure class, not just the two reproductions already seen):

1. **bin/verify_ingestion** — wrapped the whole body in `ActiveRecord::Base.transaction do ... ensure raise ActiveRecord::Rollback end`, with the pass/fail result captured via a local `error` var instead of relying on early `return`/`exit` inside the transaction. Now leaves zero rows in *any* environment (test, dev, or prod) it's run against, not just when someone remembers to clean up after `bin/smoke`.
2. **lib/tasks/quality.rake** — found a second, previously-undocumented instance of the same bug: `rake quality:all` calls `Quality::InsightIngester.ingest_*`, which persists real `SystemInsight` rows. This task runs under `RAILS_ENV=test` in **CI itself** (`.github/workflows/quality.yml` runs `bundle exec rake quality` then `bundle exec rspec` against the same Postgres service container), so this wasn't just a local-dev nuisance — it was a live, order-dependent flakiness source sitting in production CI, just not yet observed there. Added an `ingest = !Rails.env.test?` guard around all three `ingest_*` calls in the rake task (not in `Quality::InsightIngester` itself, which must keep writing normally so `spec/services/quality/insight_ingester_spec.rb` can test it under RSpec's transactional wrapper).

AC #3 (survey other bin/smoke-adjacent scripts): confirmed `bin/verify_llm.rb` is pure `Net::HTTP` — no `config/environment` load, no ActiveRecord, no DB access at all. Not a candidate for this bug class.

Verified live: `RAILS_ENV=test bundle exec ruby bin/verify_ingestion` passes and leaves `Source.count == 0` afterward; a guarded `Quality::InsightIngester.ingest_rubocop` call leaves `SystemInsight.count == 0`; `spec/services/quality/insight_ingester_spec.rb`, `spec/jobs/quality/insight_embedding_job_spec.rb`, and `spec/requests/charts/data/sources_spec.rb` (12 examples) all pass standalone and back-to-back with no manual cleanup between runs.
<!-- SECTION:FINAL_SUMMARY:END -->
