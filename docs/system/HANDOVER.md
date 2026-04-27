# Handover Protocol: Phase 13 & Beyond

## 1. The Next Objective: Phase 13 - Operational Excellence
The next agent session should focus on moving from "Modular" to "Professional Scale."

### A. Advanced Scheduling
- **Problem**: `DataAcquisitionManager` currently runs in a single-threaded loop.
- **Solution**: Decouple source fetching into individual `JobBoards::FetcherJob` instances to allow parallel execution across the Solid Queue worker pool.

### B. Deep Search Optimization
- **Goal**: Tune the ranking weights between Postgres Full-Text Search and pgvector search.
- **Task**: Implement a `Search::Ranker` service that synthesizes both scores into a single "Neural_Match" decimal.

### C. Automated Smoke Tests
- **Objective**: Automate the manual checks in `Backlog.md`.
- **Task**: Create a `bin/smoke` script that verifies:
  - Database connectivity.
  - LLM inference latency.
  - Background worker heartbeat.
  - Dashboard chart rendering.

## 2. Testing & Verification Standards
- **Golden Cassette Rule**: Never delete a VCR cassette without a corresponding change in the 3rd party API documentation.
- **Honest Mocking**: Stub the lowest level possible (Faraday/HTTP) rather than mocking service objects.
- **System Stability**: Maintain `process_timeout: 60` for Cuprite to handle high-density Turbo frames.

## 3. Maintenance Commands
- **Check Health**: `bundle exec rspec && bundle exec packwerk check`
- **Security**: `bin/brakeman --quiet -w3 --format text --no-pager`
- **Setup**: `bin/setup` (verified idempotent).
