# bin/ script conventions

## No non-transactional writes under `RAILS_ENV=test`

RSpec wraps every example in a transaction it rolls back (`use_transactional_fixtures = true`
in `spec/rails_helper.rb`). Any `bin/*` script or rake task that performs real ActiveRecord
writes when invoked directly (not through an RSpec example) has no such rollback — rows it
creates persist in the local `wwworkremote_test` database indefinitely, silently breaking any
spec that asserts an exact count.

This has independently recurred twice (see TASK-35):
- `bin/verify_ingestion` (invoked by `bin/smoke` under `RAILS_ENV=test`) left `Source` rows
  behind, breaking `spec/requests/charts/data/sources_spec.rb`.
- `rake quality`'s `Quality::InsightIngester` calls left `SystemInsight` rows behind, breaking
  `spec/jobs/quality/insight_embedding_job_spec.rb` — this one is live in CI too, since
  `.github/workflows/quality.yml` runs `bundle exec rake quality` immediately before
  `bundle exec rspec` against the same database.

**When writing or reviewing a `bin/*` script or rake task that touches the database and can
run under `RAILS_ENV=test`:**
- If the script's writes are only there to exercise a code path (a smoke/verification script),
  wrap the whole body in `ActiveRecord::Base.transaction do ... ensure raise ActiveRecord::Rollback end`
  so nothing persists in *any* environment it's run against.
- If the writes are meant to persist for real (a rake task that's supposed to produce lasting
  data), guard the write path with `return if Rails.env.test?` at the call site — not inside the
  underlying service class, since that class likely also needs to write for real when called
  directly from an RSpec example (which does get the transactional rollback).

If a spec starts failing with an "expected N, got N+k" mismatch that doesn't reproduce on a
freshly-migrated test DB, check `Model.count`/`Source.count`/etc. directly against the local
test DB before assuming generic test-order flakiness — it's often exactly this.
