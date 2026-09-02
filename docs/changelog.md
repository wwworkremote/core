# Changelog

A narrative history of this project, reconstructed from git history and
Backlog.md task records. Organized by era, not by commit — each section
covers a period of related work and calls out the architectural decisions
that shaped what came after. Commit SHAs and TASK-IDs are short-form
references for digging deeper (`git show <sha>`, `mcp__backlog__task_view`
or `backlog/tasks/task-N-*.md`).

This file replaces an earlier `CHANGELOG.md` that existed from 2026-03-02
through 2026-04-24, then was collaterally deleted in a small nav-fix commit
(`dac7c754`) and never restored. Its content (2021 through 2026-04-19) is
folded into the first three sections below.

## 2021 — First build

Project started 2021-06-19 (`f0bab275`) as a Ruby 2.7/3.0 Rails app. Basic
HackerNews job acquisition via the Firebase API, an initial dashboard with
Ahoy tracking, basic job models, database partitioning and UUID support.
Deployed via Capistrano to a home Raspberry Pi cluster (`malina`, `jagodka`,
`jablko`). ~635 commits in the first six months — a fast, exploratory build.

## 2022–2023 — Slow maintenance, then dormancy

Sparse activity across scattered months: the `JobBoards` storage namespace
introduced, Rails Event Store added for event-driven patterns (later
reversed, see ADR 001), Ruby upgraded to 3.1.x. 2023 added OpenTelemetry,
RailsAdmin with PaperTrail auditing, and PG Search. The repo then went
**dormant for roughly two and a half years** — last 2023 commit `d94fa2b6`
(2023-10-13), next commit `f3c27e45` (2026-03-02).

## 2026-03 — Revival: Rails 8, Solid stack, LLM integration

The project restarted with a systematic modernization pass, not just picking
up where 2023 left off:

- **`f3c27e45`, `bbb9613e`, `6bd40164`** — Ruby 4.0.1, Rails 8.0, Propshaft
  replacing Sprockets, Solid Cache.
- **`bfd0d6e6`** — RailsAdmin replaced with Avo 3.0 (itself later replaced by
  hand-rolled admin views — see the July hardening era).
- **ADR 002 ("Ultimate Stack Consolidation")** — the defining decision of
  this era: drop Redis entirely in favor of the "Solid" stack
  (`solid_queue`/`solid_cache`/`solid_cable` on PostgreSQL), drop Devise for
  a plain `has_secure_password` + HTTP Basic Auth model (single-user tool,
  no need for session/OAuth complexity), reject heavy serialization
  frameworks. This shaped every infrastructure decision afterward.
- **`ecd7d37f`, `c620cf28`** — RubyLLM + local Ollama integration, the start
  of this app's whole AI-assisted matching/categorization capability.
- **`96d7da0d`** — TDD-driven fetchers for Remotive, WWR, Arbeitnow, Adzuna,
  HN backfill — `JobBoards::Syncer` established as the central point mapping
  raw provider payloads onto unified `JobPosting` records.
- **ADR 001** — PaperTrail replaces Rails Event Store for auditing (RES was
  event-driven infrastructure sized for a volume this app no longer had).

## 2026-04 — AI matching, career identity, and the Chrome extension

A dense multi-week sprint (`a9ebafed` through `edcd6da3`) adding most of the
app's user-facing intelligence layer in one continuous push:

- **`a9ebafed`, `33c99fc9`** — the structured career-identity system
  (`CareerProfile`, `WorkExperience`, `ExperienceHighlight`) and user
  profile/favorites.
- **`1eabe084`** — the "Ruthless Career Advocate" AI match-analysis persona
  — still the voice behind the match-scoring feature today.
- **`a35a5a00`** — **the Chrome extension is born** (`feat(extension):
  implement Chrome Ingestion Assistant for high-fidelity capture`) — the
  browser-side capture path that TASK-37.x work in August (LinkedIn/Indeed/
  Adzuna/Wellfound extractor repairs) and the still-open TASK-37.5 (new
  provider coverage) both build on.
- **`b3268c00`** — HA/backup strategy; **`555b24b6`** — migrated off Falcon
  to Puma.
- **`ddd54452`** — "complete semantic DaisyUI Admin rewrite" — the admin UI's
  visual language (still in use, see `app/views/admin/shared/_nav.html.erb`)
  dates from here.
- **`9b33569f`** — an *earlier* typography/contrast A11y pass (2026-04-24) —
  worth knowing about if you're touching color tokens, since a second
  contrast pass happened 2026-08-19 fixing gaps this one didn't cover
  (`slate-500`/`slate-600` failing WCAG AA sitewide).
- **`d7ed2e5d` through `1222aff9`** — a 12-phase, multi-day test-hardening
  push (`test: ... (Phase 1)` through `Phase 12`) explicitly building
  toward a coverage target, ending in a security audit and command-injection
  hardening pass (`a0932805`).

## 2026-05 — Semantic search infrastructure, then a long pause

- **`949029df`, `592eecf7`** — `VectorIntelligence` module centralizing
  embedding/semantic-search operations.
- **`c35d4516`, `a857ad55`** — `Ingestion::AdapterRegistry` introduced —
  the registry-based fetcher architecture still in use (`config/initializers/
  ingestion_adapters.rb`), replacing ad hoc per-fetcher wiring.
- **`e428f1ce`, `63f0e865`** — `ResumeManager` and `JobSearchManager::
  MatcherService` as unified entry points; Resume Versioning + diffing UI
  shipped over `2026-05-05`/`06`.

Then the repo went quiet again for about **11 weeks** (last May commit
`4ee420bb` on 2026-05-06, next commit `2979cd8a` on 2026-07-27).

## 2026-07-27 to 2026-07-30 — The hardening sprint (biggest architectural shift)

This four-day span is the single most consequential block in the project's
history for *how the codebase itself is built*, not just what it does.
Roughly 150 commits, almost entirely `refactor:`/`style:`/`fix:` — no new
user-facing features:

- **Infra repair** (`2979cd8a` through `9fc573fb`, July 27): Solid Queue
  connection-pool right-sizing, Turbo broadcasts isolated to their own
  queue, launchd-based process control replacing whatever ran it before,
  bot-check/interstitial page detection added to job fetchers, email
  ingestion pipeline repaired.
- **Sandi Metz rule enforcement** (July 28-29, dozens of commits): the
  codebase was systematically walked end-to-end, splitting every
  RuboCop-flagged God method/class into named steps or extracted
  collaborators — `JobBoards::Syncer` split into 3 collaborators
  (`d830f674`), `LLM::Orchestrator` given a dedicated `Streamer`
  (`3a3d6c50`), `JobPosting` split into `LegacyCompanyAccess`/
  `StatusWorkflow` concerns (`d088e073`, still the pattern extended by
  TASK-69's `LocationFiltering`/`Geocoding` work in August), and so on
  across nearly every controller and service in the app. This is why the
  codebase reads the way it does today — small single-responsibility
  methods almost everywhere, a deliberate style, not an accident.
- **`aa422f7f`** — RuboCop cleanup finished at **zero offenses
  project-wide**, a bar the project has been held to since.
- **`dacdf5f8`, `44e1fc33`** — `erb_lint` added, and the `PostToolUse` hook
  that auto-formats every edited file on save — the exact hook
  infrastructure this session's own commits repeatedly ran into (and once,
  legitimately caught a pre-existing erb_lint failure from this very era).
- **`7cd138ab`, `35373587`** — erb_lint's autocorrect was found corrupting
  HTML structure and had to be guarded against — the same tag-count diff
  guard that saved a nav edit from corruption in this session's
  TASK-69/nav-accessibility work.
- **`de72449f`** — patched an ActiveStorage CVE (arbitrary file read/RCE).
- **`8cf5c328`, `ea75aadf`** — commute-zone filtering and big-tech
  auto-block introduced — the direct ancestors of `Geo::CommuteZone` and
  `Company::BIG_TECH_NAMES` as they exist today.
- **`7378087f`, `3cb239fc`, `f357ac70`** — OpenTelemetry instrumentation
  extended to ActiveJob enqueue spans, the 4 Playwright scrapers, and LLM
  token-usage/cost tracking.

## 2026-08 — Backlog-driven era (TASK-N tracking begins in earnest)

Commit subjects start consistently referencing `TASK-N` around 2026-08-08,
marking Backlog.md's adoption as the standing workflow (per this repo's
`CLAUDE.md`). Selected threads, not exhaustive:

- **Aug 8 — Postgres capability upgrades (task-32 milestone, 6 subtasks)**:
  keyword+vector hybrid search fusion (`26815008`), HNSW indexes, a
  `RoleFamily` title taxonomy (`ea06577d`) replacing an ad hoc management-tier
  filter, weekly trend rollups.
- **Aug 10 — Claude Code tooling**: self-verifying skills/agents (`b49a70a0`),
  a `claude-assets` validator wired into overcommit.
- **Aug 12 — Lead capture pipeline**: the extension's capture flow gets a
  `Lead`/`Company`/`Source` data model and an AI strategy layer (`f4d75e7b`),
  plus a security-review remediation pass on it (`b905dceb`).
- **Aug 14** — extraction-rule "teach flow" for the extension, geocoding/
  location-filtering refactored into concerns, `bin/wwwr` CLI and a SwiftBar
  menubar plugin shipped, UP-NW commute-line modeling for the Chicago
  suburbs use case, a 12-view i18n copy pass.
- **Aug 15** — search performance (`fffb920c`, ~3s to ~60ms), the embedding
  dimension mismatch behind hybrid search fixed (TASK-38), `Adp::Fetcher`
  and `Workday::Fetcher` — the direct-hiring-page ingestion pipeline (still
  used by TASK-68's rubyonrails.org work pattern).
- **Aug 16-17** — relevance ranking with explainable tags, auto-ignore for
  non-Engineering titles at sync time, several extension SPA-navigation
  capture bugs fixed (TASK-59/60), the admin and public job-posting views
  merged into one page (TASK-66.1), `ActiveJob::Base.queue_adapter` test
  pollution fixed at its source (`ada10848` — the actual root-cause fix
  behind TASK-56, formally verified and closed 2026-08-19).
- **Aug 18** — the Tinder-style triage queue (TASK-62), quick-filter/sort on
  the job postings index (TASK-67), TASK-66's application-assistance
  workflow completed (cover letters, change history, canned/AI Q&A),
  jobs.rubyonrails.org identified as a strong-fit source and researched
  (TASK-37.4).
- **Aug 19 (this session)** — per-source ingestion-disable and
  results-exclusion flags distinct from each other (TASK-69.1-69.2), a
  US-only country filter that turned out to already exist in
  `QualityFilter#country_mismatch?` but sat inert (TASK-69.3), a job-posting
  delete button wired onto a destroy action that had existed with no UI
  caller (TASK-69.4), jobs.rubyonrails.org ingestion via RSS (TASK-68), a
  sitewide `translation_missing` bug fixed on every nav/footer label, nav
  accessibility landmarks/skip-link/active-page state added, and a second
  contrast pass fixing `slate-500`/`slate-600` failing WCAG AA against the
  dark theme (~300 uses across 59 files).

## September 2026

- **Sep 2** — Interview Prep Pack (TASK-144): one-click LLM-generated interview
  brief per job posting — story arc, ranked company hooks, referral play,
  likely questions, questions to ask, night-before checklist — grounded in the
  structured career history, the posting, any stored Company audit, and any
  linked referral Contact. Stored on `UserJobPosting` next to the cover letter,
  editable in place and regenerable, surfaced in the Interview Notes section.
  Built by cloning the cover-letter generation path; the three POST-and-redirect
  LLM actions on `UserJobPostingsController` collapsed onto one `run_llm` helper.
  Worked reference: `docs/research/interview-prep-basis-dsp.md`.

## Where to look instead of re-reading this file

- `docs/adr/*.md` — the "why," not just the "what," for the biggest
  infrastructure calls (audit strategy, Solid stack, circuit breaker design).
- `backlog/tasks/*.md` — any `Done` task's Final Summary usually has more
  narrative detail (bugs found, tradeoffs, what was verified) than its
  commit message alone.
- `git log --oneline` — the ground truth; this file summarizes eras, it
  doesn't replace reading the actual diff when it matters.
