# Engineering Backlog: Job Search Automation Platform

## Backlog Audit
- **Status**: Updated via ADR 002 (Ultimate Stack Consolidation).
- **Task Distribution**: Finalizing the "Solid" shift and investigating new sources.
- **Major Gaps**: Otta investigation, Dynamite Jobs investigation.
- **Quality Issues**: Transaction safety and migration guardrails.

---

## Priority Backlog (Dependency-Ordered)

### 1. Implement Distributed Circuit Breaker for Rate Limiting
- **Description**: Add a non-blocking locking mechanism to job fetchers to handle HTTP 429 errors gracefully without thread-blocking sleeps.
- **Acceptance Criteria**:
  - `ApiGuard` enhanced with `lock_source!` and `source_locked?` methods using `Rails.cache`.
  - Shared `JobBoards::Client` wrapper implemented to detect `429` errors and trip the breaker.
  - High-volume fetchers (Lever/Greenhouse) refactored to check lock state before execution.
  - No `sleep` calls allowed in any fetcher path.
- **Definition of Done**:
  - Circuit trips globally for a source when a 429 is encountered.
  - Subsequent jobs for that source skip execution gracefully while the lock is active.
  - Isolation verified: Tripping Foo fetcher does not block Bar fetcher.
  - Integration test demonstrating skip-on-lock behavior.
- **Labels**: resilience, performance

### 5. Remove Devise and Simplify Auth
- **Description**: Replace the heavy Devise stack with `has_secure_password` and HTTP Basic Auth for a single-admin local tool.
- **Acceptance Criteria**:
  - `devise` gem removed.
  - `User` model updated with `password_digest`.
  - Avo dashboard protected via HTTP Basic Auth.
- **Labels**: auth, refactor

### 6. Complete Solid Queue & Cache Migration
- **Description**: Move background jobs and caching to PostgreSQL, dropping Redis entirely.
- **Acceptance Criteria**:
  - `sidekiq` removed.
  - `solid_queue` and `solid_cache` fully configured.
  - `docker-compose.yml` and `.env` cleaned of Redis.
- **Labels**: infrastructure

### 7. Implement Safety Guardrails
- **Description**: Add gems to catch bad migrations, transaction leaks, and schema inconsistencies.
- **Acceptance Criteria**:
  - `strong_migrations`, `database_consistency`, and `isolator` added.
  - Initial run of `database_consistency` passes.
- **Labels**: safety, dev-tools

### 8. Investigate Next Sources: Otta & Dynamite Jobs
- **Description**: Map out extraction strategies for Otta and Dynamite Jobs.
- **Acceptance Criteria**:
  - API endpoints or scrape targets identified.
  - Signal quality (remote, salary, tech stack) evaluated.
- **Labels**: ingestion

---

## Future Enhancements (Deferred)
- **Serialization**: Adopt `alba` for `api/v0/` if complexity increases.
- **Profiling**: Add `test-prof` to optimize slow scraper specs.
- **Headless Browser**: Move from Selenium to `cuprite` for system tests.
- **Components**: Evaluate `view_component` if custom UI becomes non-trivial.
- **SPA**: Evaluate `inertia_rails` only if complex client-side state is required.

---

## Guardrails
- **Job Idempotency**: All new workers must prove safe duplicate execution.
- **LLM Boundaries**: No LLM calls in web requests; must have timeouts and retries.
- **Query Safety**: EXPLAIN ANALYZE required for any new search or high-volume query.
- **Contract First**: No new feed source without a live contract spec.

## Tool Strategy
- **RuboCop**: Keep (Primary). Hardened with performance and rails plugins.
- **Brakeman**: Keep. Security gate.
- **Strong Migrations**: NEW. Protect production schema.
- **Isolator**: NEW. Prevent transaction bleed.
