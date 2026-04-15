# Engineering Backlog: Job Search Automation Platform

## Backlog Audit
- **Status**: Newly established from system modernization findings.
- **Task Distribution**: Focused on safety rails (Phase 1) and ingestion reliability (Phase 2).
- **Major Gaps**: Live contract tests for external feeds, AI categorization validation, OpenTelemetry verification.
- **Quality Issues**: Many tests rely on VCR cassettes which mask upstream API drift.

---

## Priority Backlog (Dependency-Ordered)

### 1. Establish External Feed Contract Tests (DONE)
- **Description**: Current tests use VCR cassettes which can become stale. We need "Live" contract tests that run on a separate CI schedule to detect when Adzuna, Remotive, or WWR change their API formats.
- **Acceptance Criteria**:
  - `spec/contracts/` directory created.
  - Live HTTP tests implemented for at least 3 major sources.
  - Tests verify presence of required keys (`title`, `url`, `company`).
- **Definition of Done**: Tests pass without VCR in a dedicated environment.
- **Labels**: testing, dependency
- **Dependencies**: None

### 2. Verify and Tune AI Categorization
- **Description**: Integrated Llama 3.2 for job categorization, but we need to verify the accuracy of the prompts and the quality of the tags being generated.
- **Acceptance Criteria**:
  - Run `HackerNews::FetchLatestWorker` on 50+ items.
  - Audit `JobPosting#tags` and `ai_category` in Avo.
  - Refine prompt if categorization is "Other" more than 20% of the time.
- **Definition of Done**: Categorization accuracy manually verified for 20+ records.
- **Labels**: llm, refactor
- **Dependencies**: None

### 3. Verify OpenTelemetry Export
- **Description**: OpenTelemetry is configured but needs verification that spans (especially the new `categorize_job` span) are reaching the Jaeger backend.
- **Acceptance Criteria**:
  - Jaeger UI (localhost:16686) shows traces from `core` service.
  - Traces correlate Sidekiq jobs to LLM categorization spans.
  - `app.job_posting.id` attribute is searchable in Jaeger.
- **Definition of Done**: Successful trace visualization confirmed.
- **Labels**: observability
- **Dependencies**: None

### 4. Audit Rails Event Store Usage
- **Description**: Rails Event Store is present but potentially underutilized or overlapping with AASM.
- **Acceptance Criteria**:
  - Document all events currently being published.
  - Ensure events are published within DB transactions.
  - Decide if RES is providing enough value over PaperTrail for audit logs.
- **Definition of Done**: ADR (Architecture Decision Record) created for RES vs PaperTrail.
- **Labels**: architecture, database
- **Dependencies**: None

---

## Guardrails
- **Job Idempotency**: All new workers must prove safe duplicate execution.
- **LLM Boundaries**: No LLM calls in web requests; must have timeouts and retries.
- **Query Safety**: EXPLAIN ANALYZE required for any new search or high-volume query.
- **Contract First**: No new feed source without a live contract spec.

## Tool Strategy
- **RuboCop**: Keep (Primary). Hardened with performance and rails plugins.
- **Brakeman**: Keep. Security gate.
- **DatabaseCleaner**: Removed. Using native transactional fixtures.
- **Reek/Fasterer**: Removed. Consolidated into RuboCop.
