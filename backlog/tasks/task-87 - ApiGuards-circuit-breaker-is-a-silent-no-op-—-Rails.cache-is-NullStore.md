---
id: TASK-87
title: ApiGuard's circuit breaker is a silent no-op — Rails.cache is NullStore
status: Done
assignee: []
created_date: '2026-08-25 13:13'
updated_date: '2026-08-25 15:54'
labels: []
dependencies: []
priority: medium
type: bug
ordinal: 100000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found while working TASK-85's country_code backfill: `Rails.cache` resolves to `ActiveSupport::Cache::NullStore` in this environment (confirmed directly -- `Rails.cache.write(k, v); Rails.cache.read(k)` returns nil).

`ApiGuard` (app/services/concerns/api_guard.rb) uses `Rails.cache` for both its cooldown tracking (`last_fetched_at`/`can_fetch?`) and its circuit breaker (`lock_source!`/`source_locked?`). With a NullStore, every write silently vanishes, so:
- `source_locked?` always returns false, even right after `lock_source!` was just called
- `JobBoards::GeocodingJob`'s rescue for `Geocoder::OverQueryLimitError` calls `lock_source!("geocoding", duration: 1.hour)`, which does nothing, so nothing stops the next call from immediately re-hitting the same rate-limited endpoint
- The same is true for every other job-board client built on `with_api_guard`, not just geocoding

Reproduced live: after Nominatim started returning `OverQueryLimitError` (from a burst of geocoding calls), repeated sequential calls one second apart kept hitting the same error indefinitely -- the circuit breaker never engaged because there was nowhere for the lock to persist.

## Acceptance criteria
- Confirm which cache store *should* be configured for development/production (SolidCache is already a dependency per config/initializers/geocoder.rb's comment referencing it) and why it's resolving to NullStore instead
- Fix the configuration so ApiGuard's lock/cooldown actually persists across calls within a process and across processes
- Verify: trigger a lock via `lock_source!`, confirm `source_locked?` returns true from a separate process/request
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Confirm which cache store should be configured for development/production and why it's resolving to NullStore instead
- [x] #2 Fix the configuration so ApiGuard's lock/cooldown actually persists across calls within a process and across processes
- [x] #3 Verify: trigger a lock via lock_source!, confirm source_locked? returns true from a separate process/request
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Root cause: `Rails.cache` is intentionally `NullStore` in development unless `bin/rails dev:cache` has been run (stock Rails toggle for view/fragment caching, `config/environments/development.rb:29-41`). Production and test are fine (`solid_cache_store` / `memory_store` unconditionally). `ApiGuard` was piggybacking functional circuit-breaker/cooldown state on that toggle, so in the default dev state every `lock_source!` write silently vanished.

Fix: `ApiGuard` no longer touches `Rails.cache` at all. Added `ApiGuard.store`, which calls `ActiveSupport::Cache.lookup_store(:solid_cache_store)` directly -- bypassing `config.cache_store` and its dev on/off toggle entirely, in every environment. SolidCache already runs on the app's single primary DB (no separate `connects_to`), so this persists across processes and rolls back transactionally inside specs like any other AR-backed write.

Updated the 4 call sites inside `app/services/concerns/api_guard.rb` plus the 3 spec files that poked `Rails.cache` directly to simulate lock state (`spec/integration/circuit_breaker_spec.rb`, `packages/ingestion/spec/jobs/job_boards/geocoding_job_spec.rb`, `packages/ingestion/spec/jobs/hacker_news/fetch_jobstory_job_spec.rb`) to use `ApiGuard.store` instead. All 24 examples across those specs pass.

Verified the AC's exact scenario manually: `lock_source!` in one `bin/rails runner` process, `source_locked?` reads `true` from a second, separate process.

Did not touch Geocoder's own `cache: Rails.cache` line-cache config (`config/initializers/geocoder.rb`) -- that's a performance cache for repeated identical lookups, not correctness-critical, and out of scope for this ticket.
<!-- SECTION:FINAL_SUMMARY:END -->
