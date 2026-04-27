# System Health & State Registry
**Last Synchronized**: Sunday, April 27, 2026

## 1. Executive Summary
The platform has transitioned from a monolith to a domain-driven, modular architecture. It is currently hardened against data corruption, AI hallucinatory drift, and security vulnerabilities.

| Metric | Status | Note |
| :--- | :--- | :--- |
| **Test Suite** | 230 Passing | 100% Success Rate |
| **Line Coverage** | ~65% | Critical logic (AI/Ingestion) > 90% |
| **Architecture** | Verified Modular | 0 Packwerk Violations |
| **Security** | Hardened | 0 Brakeman Warnings |
| **Infrastructure** | Solid Stack | No Redis dependency; DB-backed scaling |

## 2. Core Architectural Pillars

### A. Modular Ingestion (`packages/ingestion`)
- **Isolation**: Interacts with Core ONLY via `JobPosting` and `JobBoards::Document` records.
- **Contract Enforcement**: Every provider (Indeed, LinkedIn, Glassdoor, Dice, Remotive, WWR, Arbeitnow, BuiltIn, RemoteIO, EchoJobs, Cruit) has a verified "Extraction Contract" in `extractor_contract_spec.rb`.
- **Resilience**: `ApiGuard` implements distributed circuit breakers using `Rails.cache`.

### B. AI Orchestration Layer
- **Registry**: `LLM::Registry` synchronizes models from `config/models.yml`.
- **Guardrails**: All LLM interactions are filtered through `Guardrails::Pipeline` (Heuristics -> Execution -> Normalization -> Validation).
- **Match Engine**: `LLM::ProfileMatcher` calculates semantic alignment between User profiles and Job postings.

### C. The "Solid" Infrastructure
- **Queue**: `SolidQueue` for background jobs (High/Medium/Light buckets).
- **Cable**: `SolidCable` for Turbo Stream real-time dashboard updates.
- **Cache**: `SolidCache` for cross-process circuit breaker state.

## 3. Security Hardening
- **Command Injection**: Purged all `spawn` calls; recurring tasks are now whitelisted and executed via direct Ruby methods.
- **Open Redirects**: `OutboundLinksController` verifies target URLs against the job database before redirecting.
- **AASM Whitelisting**: Pipeline state transitions are restricted to a defined event whitelist to prevent arbitrary method execution.

## 4. Known Verification Gaps (The "35%")
- **Admin UI Edge Cases**: Bulk merging of companies lacks exhaustive system specs.
- **Infra Scripts**: Low-level bin scripts (`update-geoip`) are manually verified but not under RSpec.
- **Vector Benchmarks**: While retrieval works, the "cosine distance" weights haven't been optimized for high-volume ranking.
