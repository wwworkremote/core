---
id: TASK-87
title: ApiGuard's circuit breaker is a silent no-op — Rails.cache is NullStore
status: To Do
assignee: []
created_date: '2026-08-25 13:13'
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
