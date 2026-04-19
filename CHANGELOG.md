# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2026-04-19

### Added
- **Career Identity System**: Deeply structured resume and job history modeling (`WorkExperience`, `ExperienceHighlight`, `CareerProfile`).
- **Resume YAML Importer**: Automatic ingestion and date-type casting of high-fidelity career data from Jekyll-based sources.
- **Mass-Scale Ingestion Pipeline**: Distributed `Scraper::Crawler` and `DiscoveryLink` architecture for high-throughput job discovery.
- **AI Match Intelligence (V2)**: "Ruthless Career Advocate" persona for personalized semantic alignment scans between resume and job postings.
- **Pipeline Health Monitor**: SLO-driven dashboard widget tracking Sync latency, Ingestion freshness, and operational health.
- **Company Research Dashboard**: Centralized intelligence hub for tracking company-level engagement and associated job timelines.
- **API-First Scraping Strategy**: `ApiInterceptor` for Playwright-based discovery of hidden JSON/GraphQL endpoints to bypass HTML scraping.
- **Granular Email Ingestion**: Independent pipelines for Indeed, Adzuna, and LinkedIn email streams with automated scheduling.
- **Development Tooling**: Integrated `guard-livereload` for accelerated UI feedback loops.

### Changed
- **Unified Research UI**: Merged Admin-only research tools directly into the primary Job Posting and Company views.
- **Orchestrator Refactor**: Streamlined LLM execution to leverage native `RubyLLM` ask-and-stream patterns.
- **Data Fetcher Grouping**: Reorganized orchestration dashboard into technical categories (API, Feed, Email, Scraper) with bulk-trigger support.
- **LLM Infrastructure**: Hardened local `llama.cpp` integration with standalone verification scripts and object-based message wrappers.

### Fixed
- **Sync/Ingest Visibility**: Resolved "NEVER" status issues by falling back to model-level timestamps.
- **UI Robustness**: Applied safe navigation and fallback logic for missing metadata (company names, publication dates).
- **Background Jobs**: Corrected argument handling for ActiveJob-based fetchers and Rake-delegated email imports.

## [0.2.0] - 2026-03-02

### Added
- **Job Browsing Interface**: New searchable and paginated UI for discovering and reading job postings.
- **New Data Sources**: TDD-driven integration for Remotive (JSON API), We Work Remotely (RSS), Arbeitnow (JSON API), and Adzuna (JSON API).
- **HackerNews Backfill**: Historic data acquisition via Algolia HN Search API.
- **JobBoards::Syncer**: Centralized service to map raw document data from multiple sources to unified JobPosting records.
- **Infrastructure**: Dockerized the entire application with `docker-compose` and persistent named volumes.
- **Rate Limiting**: Implemented `ApiGuard` using Kredis for source cooldowns and staggered HN fetching with randomized delays.
- **Testing**: Modernized test suite with RSpec, VCR, WebMock, shoulda-matchers, and DatabaseCleaner.
- **Host Scripts**: Added `bin-host/` scripts for manual and automated fetching from the host machine.

### Changed
- **Consolidation**: Merged legacy `dashboard` and `core` into a single Rails 7.2 application.
- **Modernization**: Upgraded Ruby to 3.3.4 and Rails to 7.2.
- **Architecture**: Removed complex distributed physical node logic in favor of a simpler containerized Sidekiq architecture.
- **UI**: Replaced Webpacker with Sprockets/Importmaps and integrated Bootstrap 5 (Morph theme).

### Removed
- **Legacy Components**: Pruned redundant `dashboard/`, `ops/`, `actions/`, and `binder/` directories.
- **Unused Gems**: Removed `sidekiq-throttled`, `ox`, `nori`, and other legacy dependencies.
- **Ghost APIs**: Pruned references to inactive Indeed, Lever, and Greenhouse integrations.

## [Legacy Core] - 2021 to 2023

### 2023 Notable Updates
- Integrated OpenTelemetry (OTEL) for observability.
- Added RailsAdmin with PaperTrail support for auditing.
- Implemented PG Search for better data discoverability.
- Initial distributed fetcher logic using hostname-based node mapping.

### 2022 Notable Updates
- Initial implementation of the `JobBoards` storage namespace.
- Added Rails Event Store (RES) for event-driven patterns.
- Migrated to Ruby 3.1.x.
- Set up Capistrano-based deployment for Raspberry Pi cluster (`malina`, `jagodka`, `jablko`).

### 2021 Notable Updates
- **Initial Commit**: Project started as a Ruby 2.7/3.0 application.
- Basic HackerNews acquisition via Firebase API.
- Initial dashboard structure with Ahoy tracking and basic job models.
- Database partitioning and UUID support added.
