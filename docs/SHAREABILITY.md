# 🚀 WWWorkRemote: Shareability Roadmap & Pitch

## 1. The Pitch: Your Personal Career Intelligence Engine

**WWWorkRemote** is a self-hosted, AI-powered command center that automates the "grunt work" of a high-end remote job search. It treats your career search like a mission-critical engineering project.

### Why it exists:
- **Fight Fragmented Boards**: Aggregates LinkedIn, Indeed, Glassdoor, Dice, and Hacker News.
- **Privacy First**: Your resume and goals never leave your machine; all AI analysis happens via a local LLM.
- **Deep Alignment**: Don't just find jobs; find the 1% that match your "Remote Purity" and tech stack requirements.
- **Execution Intelligence**: Monitor your search with a sophisticated dashboard showing queue throughput and real-time ETAs.

---

## 2. Stability Assessment (Current State)
**Rating: 7.5 / 10**

- **Architecture (8.5/10)**: Rock-solid, PostgreSQL-only stack (Solid Queue, Solid Cache, Solid Cable). No external dependencies like Redis.
- **Autoloading (9/10)**: Standardized on `LLM` naming and verified via `zeitwerk:check`.
- **Ingestion (7/10)**: Robust Playwright-based scraping for Indeed and LinkedIn. Highly dependent on job board HTML stability.
- **Testing (6/10)**: Core models and ingestion flows verified via system specs. Significant gap in service-level unit tests.

---

## 3. Security Audit Findings (Brakeman)
**Audit Date: April 22, 2026**

### High Priority Fixes Required:
1. **Command Injection**: `Admin::JobsController` uses `spawn` with YAML-loaded commands. Needs strict whitelist validation of `task_id`.
2. **Dangerous Send**: `Company` and `JobPosting` pipeline controllers use `send("#{params[:status]}!")`. This must be replaced with an allowed list of AASM events.
3. **Remote Code Execution**: `constantize` called on YAML-loaded class names in `Admin::JobsController`. Needs class name whitelisting.

---

## 4. Shareability Roadmap (The Path to 1.0)

### Phase 1: Robustness & Security (Active)
- [ ] Fix Brakeman security vulnerabilities (Injection/Dangerous Send).
- [ ] Complete Spec Audit: Ensure 100% coverage for all models, controllers, and services.
- [ ] Enable **Bullet** in development to catch N+1 queries early.

### Phase 2: One-Command Setup
- [ ] Refactor `bin/setup` to be idempotent and handle:
    - Ruby/Postgres environment check.
    - `playwright install`.
    - `llama.cpp` server connectivity verification.
- [ ] Create `README_COMMUNITY.md` with simple "Quick Start" instructions.

### Phase 3: Community Contribution
- [ ] Define `CONTRIBUTING.md` with a "Virtuous Loop" guide (RSpec -> RuboCop -> Brakeman).
- [ ] Document the Crawler API to make it easy for others to add new job boards.
- [ ] Add `ahoy_captain` dashboards for shared analytics insights.

---

## 5. The Virtuous Loop Guide
For all contributors:
1. **Develop**: Write your feature or fix.
2. **Test**: Run `RAILS_ENV=test bundle exec rspec` (Success is mandatory).
3. **Align**: Run `bundle exec rubocop -A` to fix style/alignment.
4. **Audit**: Run `bundle exec brakeman` to check for security regressions.
5. **Verify**: Run `bin/rails zeitwerk:check` to ensure the app boots.
