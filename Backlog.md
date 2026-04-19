# Engineering Backlog: Job Search Automation Platform

## Backlog Audit
- **Status**: Synchronized with active mass-scraping and AI-alignment features.
- **Current Focus**: Scaling ingestion pipelines and refining personal career matching.
- **Recent Major Wins**: Unified Admin/User Research UI, Distributed Crawler Discovery, and API-First Scraping Strategy.

---

## Priority Backlog (Dependency-Ordered)

### 1. Implement Distributed Circuit Breaker for Rate Limiting
- **Description**: Add a non-blocking locking mechanism to job fetchers to handle HTTP 429 errors gracefully.
- **Acceptance Criteria**:
  - `ApiGuard` enhanced with `lock_source!` and `source_locked?`.
  - Shared `JobBoards::Client` trips the breaker on 429s.
- **Labels**: resilience, performance

### 2. Scale Job Board Discovery & Ingestion
- **Description**: Scale the `Scraper::CrawlDiscoveryJob` to cover the full matrix of prioritized boards.
- **Tasks**:
  - [ ] Implement `Scraper::Indeed::ApiClient` (API-first).
  - [ ] Implement `Scraper::LinkedIn::ApiClient` (API-first).
  - [ ] Add Glassdoor and Dice crawler patterns to `DiscoveryLink` filtering.
- **Labels**: ingestion, scraper

### 3. Deep AI Career Alignment (V2)
- **Description**: Refine the `Llm::ProfileMatcher` to provide more granular, multi-stage analysis.
- **Acceptance Criteria**:
  - [ ] Support multi-document resume uploads (PDF/Docx).
  - [ ] Add "Actionable Interview Prep" section to the match analysis.
  - [ ] Enable "Career Comparison" to compare 3 job nodes against profile simultaneously.
- **Labels**: ai, product

### 4. Golden Signals & Behavioral Analytics Dashboard
- **Description**: Move beyond simple sync timestamps to a full observability dashboard.
- **Tasks**:
  - [ ] Implement Latency (Duration), Traffic (Volume), Errors, and Saturation charts in Admin.
  - [ ] Build "Behavioral Intelligence" dashboard for Ahoy event flow.
- **Labels**: monitoring, analytics

---

## Recently Completed
- [x] **Unify Research UI**: Merged Admin pipeline tools into primary `JobPosting` and `Company` views.
- [x] **Mass Ingestion Foundation**: Distributed `Scraper::Crawler` and `DiscoveryLink` architecture established.
- [x] **Career Identity Hub**: Implemented editable job history and goals for personalized AI matching.
- [x] **API-First Scraping**: Built `ApiInterceptor` to bypass HTML scraping via browser-internal endpoints (Cord.com proven).
- [x] **Pipeline Health SLOs**: Status/Sync/Ingest tracking added to the orchestration dashboard.
- [x] **Simple Auth & Solid Migration**: Dropped Redis/Devise for a lean PostgreSQL-only stack.

---

## Future Enhancements
- **Serialization**: Adopt `alba` for `api/v0/` if complexity increases.
- **Notification Engine**: Trigger email/Slack alerts when a "High Confidence Match" is ingested.
- **Browser Farm**: Evaluate `Browserless.io` or similar if local Chromium becomes a resource bottleneck.
- **Semantic Search (V2)**: Enable full-profile-to-database vector similarity search ("Find all jobs matching my entire resume").

---

## Guardrails
- **Job Idempotency**: All new workers must prove safe duplicate execution.
- **LLM Boundaries**: No LLM calls in web requests; must use `AsyncJobAdapter`.
- **Crawler Politeness**: Respect `robots.txt` and implement randomized jitter on browser sessions.
- **Data Privacy**: Profile and Match data must remain strictly isolated to the authenticated user.
