# Engineering Backlog: Job Search Automation Platform

## Completed Phases (Stability & Modularization)
- [x] **Phase 1: Ingestion Hardening**: Established full system flow spec and hardened Syncer/Crawler.
- [x] **Phase 2: LLM Logic Isolation**: Implemented realistic WebMock tests for Orchestrator/Categorizer.
- [x] **Phase 3: Coverage Gap Filling**: Added request specs for key controllers (LLM, Companies, Admin Ops).
- [x] **Phase 4: Resilience & Infrastructure**: 100% coverage for Guardrails; hardened ApiGuard.
- [x] **Phase 5: External Contracts**: Established extraction contracts and Golden Cassette audit.
- [x] **Phase 6: Search & AI Alignment**: Hardened CompanyAuditor, ProfileMatcher, and Indeed scraper.

## Phase 7: The Final Ingestion Sweep & Ops Coverage
- [x] **Phase 7: The Final Ingestion Sweep & Ops Coverage**: Implemented request specs for Admin Tasks, Models, and Domains; completed scraper specs for Dice, LinkedIn, and Glassdoor.

- [x] **Phase 8: Search & UX Hardening**: Verified end-to-end user flows (Favorite -> Match) and Neural Dialogue UI; hardened search filtering and infrastructure jobs.

- [x] **Phase 9: The Final Ingestion Sweep & External Hardening**: Secured outbound link tracking; completed error-path coverage for all major fetchers; verified email ingestion resilience.

## Phase 10: Performance & Scale Hardening
- [ ] **Data Acquisition Manager Optimization**: Implement specs for batch execution, concurrency management, and source-level audits.
- [ ] **JobBoards::Client Resilience**: Build specs for connection timeouts, retry logic, and proxy rotation simulations.
- [ ] **Observability Verification**: Implement request specs for `Charts::Data` controllers and `Admin::Observability` telemetry (0% coverage).
- [ ] **Vector Sync Reliability**: Harden `InsightEmbeddingJob` against intermittent LLM/Connectivity issues with exponential backoff verification.


- **Recent Major Wins**: Unified Admin/User Research UI, Distributed Crawler Discovery, Robust Indeed/LinkedIn Scraping, and MacOS Fork Safety hardening.

---

## Priority Backlog (Dependency-Ordered)

### 1. Implement Distributed Circuit Breaker for Rate Limiting
- **Description**: Add a non-blocking locking mechanism to job fetchers to handle HTTP 429 errors gracefully.
- **Acceptance Criteria**:
  - [x] `ApiGuard` enhanced with `lock_source!`, `unlock_source!`, and `source_locked?`.
  - [x] Shared `JobBoards::Client` trips the breaker on 429s.
- **Labels**: resilience, performance

### 2. Scale Job Board Discovery & Ingestion
- **Description**: Scale the `Scraper::CrawlDiscoveryJob` to cover the full matrix of prioritized boards.
- **Tasks**:
  - [x] Implement `Scraper::Indeed::ApiClient` (Robust Scraping).
  - [x] Implement `Scraper::LinkedIn::ApiClient` (Robust Scraping).
  - [x] Add Glassdoor and Dice crawler patterns to `DiscoveryLink` filtering.
- **Labels**: ingestion, scraper

### 3. Deep AI Career Alignment (V2)
- **Description**: Refine the `LLM::ProfileMatcher` to provide more granular, multi-stage analysis.
- **Acceptance Criteria**:
  - [x] Support multi-document resume uploads (PDF/Docx) via `LLM::DocumentProcessor`.
  - [x] Add "Actionable Interview Prep" section to the match analysis.
  - [x] Enable "Career Comparison" to compare 3 job nodes against profile simultaneously.
- **Labels**: ai, ux, profiles

### 4. Golden Signals & Behavioral Analytics Dashboard
- **Description**: Move beyond simple sync timestamps to a full observability dashboard.
- **Tasks**:
  - [x] Implement Latency (Duration), Traffic (Volume), Errors, and Saturation charts in Admin.
  - [x] Build "Behavioral Intelligence" dashboard for Ahoy event flow.
- **Labels**: monitoring, analytics

---

## Backlog Decisions (ADR)

### ADR 001: Audit Strategy - PaperTrail vs Rails Event Store
- **Context**: Need for record versioning and auditing, specifically for AI-generated categorization.
- **Decision**: Remove Rails Event Store (RES) and utilize **PaperTrail**.
- **Rationale**: PaperTrail is simpler for field-level auditing and the current data flow doesn't justify full event-sourcing.
- **Status**: Implemented.

### ADR 002: Ultimate Stack Consolidation
- **Context**: Infrastructure was overly complex for a single-user tool.
- **Decision**: Shift to "Solid" stack (`solid_queue`, `solid_cache`, `solid_cable`), remove Redis, and simplify authentication (HTTP Basic + User model).
- **Rationale**: Reduced memory footprint, simplified local setup, and improved data integrity.
- **Status**: Implemented.

### ADR 003: Distributed Circuit Breaker for Rate Limiting
- **Context**: Susceptibility to HTTP 429 rate limits in fetchers.
- **Decision**: Implement a **Distributed Circuit Breaker** using `Rails.cache` (backed by PostgreSQL).
- **Rationale**: Prevents hammering external APIs, improves resource efficiency by not blocking worker threads.
- **Status**: Implemented.

---

## Backlog Tasks (Consolidated)

### Phase 1: Robustness & Security
- [ ] **Fix Brakeman security vulnerabilities**:
  - Whitelist `task_id` in `Admin::JobsController` to prevent command injection.
  - Whitelist AASM events in pipeline controllers to prevent dangerous `send`.
  - Whitelist class names in `Admin::JobsController` to prevent RCE via `constantize`.
- [ ] **Complete Spec Audit**: Ensure 100% coverage for all models, controllers, and services.
- [x] **Enable Bullet**: Catch N+1 queries in development early.

### Phase 2: One-Command Setup
- [ ] **Refactor bin/setup**: Ensure idempotency and verify `playwright` + `llama.cpp` server connectivity.
- [ ] **Create README_COMMUNITY.md**: Provide simple "Quick Start" instructions for contributors.

### Phase 3: Community & Insights
- [ ] **Define CONTRIBUTING.md**: Establish the "Virtuous Loop" (RSpec -> RuboCop -> Brakeman).
- [ ] **Document Crawler API**: Simplify adding new job board integration.
- [ ] **Advanced Captain Dashboards**: Add `ahoy_captain` for deeper shared analytics insights.

---

## Recently Completed
- [x] **Syncer Resilience**: Hardened `JobBoards::Syncer` with generic mappers.
- [x] **Unify Research UI**: Merged Admin tools into primary `JobPosting`/`Company` views.
- [x] **Mass Ingestion Foundation**: Distributed `Scraper::Crawler` established.
- [x] **Career Identity Hub**: implemented job history and goals.
- [x] **API-First Scraping**: Built `ApiInterceptor` for Playwright-based discovery.
- [x] **Simple Auth & Solid Migration**: Dropped Redis/Devise for lean PostgreSQL stack.

---

## Operational Verification Checklist
Smoke tests to confirm the running system is healthy.

- [ ] **Email Ingestion**: Place a `.eml` in `~/.wwworkremote/indeed/` and run `bin/rake eml:scan`.
- [ ] **AI inference**: Run `ruby bin/verify_llm.rb`.
- [ ] **Background queue**: Confirm Solid Queue dashboard at `/jobs`.
- [ ] **Analytics**: Confirm `/admin/observability` charts render.

---

## Guardrails
- **Job Idempotency**: All new workers must prove safe duplicate execution.
- **LLM Boundaries**: No LLM calls in web requests; must use `AsyncJobAdapter`.
- **Crawler Politeness**: Respect `robots.txt` and implement randomized jitter.
- **Data Privacy**: Profile data must remain isolated to the authenticated user.
