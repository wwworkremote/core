# bin/ scripts — what exists and when to reach for it

A one-line index so "is there already a tool for this" has a fast answer instead of a repo
search. Each entry: what it does, and when you'd actually reach for it. Scripts not listed here
are Rails/Bundler/Kamal defaults (`bin/rails`, `bin/rake`, `bin/bundle`) — no project-specific
guidance needed.

## Service lifecycle (local dev)

- **`bin/wwworkremote-ctl`** — launchd-backed start/stop/status for local dev services (web +
  jobs), replacing the old foreman-based flow (TASK-28). This is how you actually bring the app
  up/down day to day.
- **`bin/wwworkremote-web`** / **`bin/wwworkremote-jobs`** — launchd entry points registered by
  `wwworkremote-ctl`. Not meant to be run by hand.
- **`bin/dev`** — Rails' own dev-server boot script (debug gem remote-connection setup). Use
  `wwworkremote-ctl` for normal day-to-day start/stop instead; this is the lower-level primitive
  it wraps.
- **`bin/services`** — macOS fork-safety wrapper for Puma workers under Ruby 4.0/Rails 8. Usage:
  `bin/services <command> [service|all] [options]`.

## Status and health

- **`bin/wwwr`** — the main operational CLI: `bin/wwwr status`, `bin/wwwr postings [filters]`,
  `bin/wwwr transition <id> <event>`. `--help` is current and accurate. This is the fastest way
  to answer "what's the state of the pipeline / a specific posting" without writing a
  `bin/rails runner` one-liner.
- **Pipeline health skill** (`.claude/skills/pipeline-health/`) — deeper live audit than
  `bin/wwwr status`: ingestion volume trend, SolidQueue backlog, failed-job classification
  (code bug vs. worker/infra), recurring-job schedule cross-check. Use when something's actually
  wrong, not for a routine check.

## Verification / smoke scripts

All of these are read-mostly and safe to run against development; none should be run under
`RAILS_ENV=test` (see `docs/agents/bin-script-conventions.md` for why) — `bin/verify_board` and
`bin/verify_ingestion` refuse to on their own, the others don't yet.

- **`bin/smoke`** — orchestrates `verify_llm.rb` + `verify_ingestion` + `verify_email_ingestion`;
  the "is the stack basically alive" check.
- **`bin/verify_llm.rb`** — pure HTTP health check against the local llama.cpp server (health,
  model alias, inference, embeddings). No Rails, no DB.
- **`bin/verify_ingestion`** — exercises the HackerNews fetch → `JobBoards::Syncer` path with
  dummy data, wrapped in a rolled-back transaction so nothing persists.
- **`bin/verify_board`** — see `direct-hiring-board-verify` skill below; checks one real company
  on a board-based adapter (adp/workday/greenhouse/lever) end-to-end.
- **`bin/verify_email_ingestion`** — runs `EmailIngestion::Scanner` against whatever's actually in
  `~/.wwworkremote/{source}/*.eml` right now; zero files is a healthy pass, not a failure.
- **`bin/verify_promote.rb`** — live capture→promote check for one job-board URL, bypassing the
  Chrome extension (extension automation doesn't work in this environment — see
  `docs/extension-workflow.md`). `Usage: bin/verify_promote.rb --provider X --url URL`.
- **`bin/verify_ai`** — AI-subsystem check (RubyLLM config, RAG/registry wiring).
- **`bin/verify_claude_assets`** — validates every `.claude/skills/**/SKILL.md` and
  `.claude/agents/*.md` is self-describing (frontmatter present, required fields filled). Runs
  automatically as a pre-commit hook — see the `[ClaudeAssets]` check.

## Ingestion triggers (manual, outside the normal schedule)

- **`bin/fetch-jobs`** — one-command fetch + embed + rank, for a manual full pass outside
  SolidQueue's recurring schedule.
- **`bin/trigger_scrapers.rb`** — manually kick a scraper run.
- **`bin/seed_crawler_queries.rb`** — seed `Scraper::CrawlDiscoveryJob`-backed sources' initial
  queries.
- **`bin/capture_cord_api.rb`**, **`bin/capture_cord_search_api.rb`**,
  **`bin/capture_indeed_api.rb`** — one-off raw-response capture scripts used while
  reverse-engineering a provider's API shape (see the ADP/Workday adapters' git history for the
  same technique). Reference material for building a new adapter, not part of the regular
  pipeline.

## User-facing / one-off

- **`bin/apply`** — `bin/apply <job_id>`: generates and clipboard-copies an application package
  for one JobPosting.

## Infra / ops

- **`bin/register-nginx-conf`**, **`bin/register-puma-service`** — one-time local-machine setup,
  not part of the normal dev loop.
- **`bin/update-geoip`** — refreshes the MaxMind GeoIP database used by `geocoder`.
- **`bin/docker-entrypoint`** — container boot script (pidfile cleanup, migrate-on-boot). Docker
  only, not for local dev.
- **`bin/ci`** — runs GitHub Actions locally via `act`, for testing workflow changes before
  pushing.
- **`bin/lint_extension`** — lints `extension/**/*.js`; also runs automatically as a pre-commit
  hook.
- **`bin/rspec-precommit`** — the suite runner Overcommit's `PreCommit::RSpec` hook invokes. Not
  for manual use; run `bundle exec rspec` directly instead. It exists because configuring
  `include:` on that hook (so extension-JS/docs-only commits skip the suite) also makes Overcommit
  append the matched staged files as rspec arguments — this ignores them and runs the fixed
  `spec packages/ingestion/spec` set. Don't add file arguments to it.

## Related skills (`.claude/skills/`)

- **`pipeline-health`** — is the ingestion pipeline actually producing data right now.
- **`backlog-audit`** — find duplicate/stale Backlog.md tasks before a planning pass.
- **`direct-hiring-board-verify`** — onboard a new company on ADP/Workday/Greenhouse/Lever.
