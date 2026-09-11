# ADR 003: Distributed Circuit Breaker for Rate Limiting

## Status
Proposed

## Context
Our job fetchers (e.g., Lever, Greenhouse) often iterate over multiple targets (boards, sites, terms). These high-frequency requests are susceptible to HTTP 429 (Too Many Requests) rate limits. Current mechanisms (`ApiGuard`) only manage macro-level cooldowns (starting a fetch), but don't handle mid-flight rate limit hits. Blocking execution with `sleep` is undesirable as it ties up background workers and wastes resources.

## Decision
We will implement a **Distributed Circuit Breaker** using `Rails.cache` (backed by `SolidCache`/PostgreSQL).

1.  **Stateful Locking**: Enhance `ApiGuard` to manage "Rate Limit Locks" (`api_lock:[slug]`).
2.  **Automated Tripping**: Implement a shared `JobBoards::Client` wrapper around Faraday that intercepts 429 responses and automatically trips the lock for the affected source.
3.  **Graceful Bypass**: Refactor fetchers to be granular (individual board/term fetches as separate jobs). Every job will check the circuit state (`source_locked?`) at initialization and exit immediately if the circuit is open.
4.  **No Blocking**: Explicitly forbid the use of `Kernel.sleep`.

## Consequences
- **Resilience**: A rate-limit hit on one source will protect that source from further hammering while allowing other fetchers to continue unaffected.
- **Resource Efficiency**: Workers will not be occupied by "sleeping" threads; they will simply drop locked jobs and move to the next available task.
- **Simplicity**: No new infrastructure (like Redis) or complex state machines are required. We leverage the existing database-backed cache.
- **Observability**: Tripping the circuit provides a central, loggable event for monitoring external API health.
