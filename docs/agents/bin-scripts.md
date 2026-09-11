# bin/ scripts — what exists and when to reach for it

A one-line index so "is there already a tool for this" has a fast answer instead of a repo
search. Each entry: what it does, and when you'd actually reach for it. Scripts not listed here
are Rails/Bundler/Kamal defaults (`bin/rails`, `bin/rake`, `bin/bundle`) — no project-specific
guidance needed.

## Service lifecycle (local dev)

- **`bin/wwwr-ctl`** — launchd-backed start/stop/status for local dev services (web +
  jobs), replacing the old foreman-based flow (TASK-28). This is how you actually bring the app
  up/down day to day.
- **`bin/wwwr-web`** / **`bin/wwwr-jobs`** — launchd entry points registered by
  `wwwr-ctl`. Not meant to be run by hand.
- **`bin/dev`** — Rails' own dev-server boot script (debug gem remote-connection setup). Use
  `wwwr-ctl` for normal day-to-day start/stop instead; this is the lower-level primitive
  it wraps.
- **`bin/services`** — macOS fork-safety wrapper for Puma workers under Ruby 4.0/Rails 8. Usage:
  `bin/services <command> [service|all] [options]`.

## Status and health

- **`bin/wwwr`** — the main operational CLI: `bin/wwwr status`, `bin/wwwr postings [filters]`,
  `bin/wwwr transition <id> <event>`, `bin/wwwr match <id> --source=<n>`,
  `bin/wwwr interview-prep <id> [--regenerate] [--spoken] [--export[=<role>]]`.
  `bin/wwwr --help` for the summary, `bin/wwwr help <command>` for a command's detail.
  `man ./man/wwwr.1` for the full page. Shell completion: `completions/wwwr.bash` (source from
  `~/.bashrc`) / `completions/wwwr.zsh` (add `completions/` to `fpath` before `compinit`).
  This is the fastest way to answer "what's the state of the pipeline / a specific posting"
  without writing a `bin/rails runner` one-liner. Interview-prep tooling:
  `docs/interview-prep/README.md`, diagrams in `docs/architecture/interview-prep-tooling.md`.
- **Pipeline health skill** (`.claude/skills/pipeline-health/`) — deeper live audit than
  `bin/wwwr status`: ingestion volume trend, SolidQueue backlog, failed-job classification
  (code bug vs. worker/infra), recurring-job schedule cross-check. Use when something's actually
  wrong, not for a routine check.

## Application-history backfill

All three write both `JobPosting` and `UserJobPosting` (separate state machines that drift when
only one moves — TASK-82), are idempotent, and share `Applications::PostingMatcher` so the same
application arriving from several sources is counted once. **Always `--dry-run` first.**

Inputs live in `~/ai/inbox` (moved there 2026-08-24 — `~/Desktop` is TCC-blocked and
unreadable from agent environments). That directory also holds financial PII and cookie-bearing
HAR captures: read the specific file named for the task, never enumerate the directory.

- **`bin/import_greenhouse_applications <har> [--dry-run]`** — parses a HAR capture of
  `my.greenhouse.io` for `applications.json`, which **aggregates across every Greenhouse tenant**
  rather than one company board (verified 2026-08-24; this is why Greenhouse is Tier 1, not
  Tier 3). Gives exact ISO `applied_at` timestamps. HAR bodies mix base64 and plain text within
  one capture — the script checks `.response.content.encoding`; reading only `.text` silently
  drops rows.
- **`bin/import_indeed_applications <har> [--dry-run]`** — same shape, reading
  `myjobs.indeed.com/api/v1/appStatusJobs` out of a HAR. The saved DOM is useless here: Indeed
  renders its list by XHR after load, so "Save Page As" captures an app shell with zero job ids.
  `applyTime` is epoch ms and exact. The payload also carries employer/candidate status, which
  no importer reads yet.
- **`bin/import_linkedin_tracker <stage> <saved-html> [--dry-run]`** — reads a "Save Page As →
  Complete" of `linkedin.com/jobs-tracker/?stage=<applied|clicked_apply|saved>` and records the
  applications in it. LinkedIn has no export and no tracker API, and the list is client-rendered,
  so the saved DOM is genuinely the only source. Dedups on the LinkedIn job id inside
  `target_url` (the same posting also arrives via LinkedIn job-alert emails), writes both
  `JobPosting` and `UserJobPosting`, and records `clicked_apply` as *favorite* rather than
  applied — LinkedIn only knows he left for the employer's site, not that he finished.
  Always `--dry-run` first; it prints create/backfill per row without writing.
  Caps at whatever the page had loaded, ~10 rows per stage, so scroll before saving.

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
- **`bin/backfill_country_codes [--dry-run|--status]`** — TASK-85: enqueues `JobBoards::GeocodingJob`
  for postings with a location string but no `country_code`, so the historical backlog (4,150 nil
  rows as of 2026-08-24) narrows over time via the same Nominatim lookup the live pipeline already
  uses. `--status` prints current counts with no writes; safe to re-run anytime to check progress.

## User-facing / one-off

- **`bin/apply`** — `bin/apply <job_id>`: generates and clipboard-copies an application package
  for one JobPosting.

## Infra / ops

- **`bin/register-nginx-conf`**, **`bin/register-puma-service`** — one-time local-machine setup,
  not part of the normal dev loop.
- **`bin/update-geoip`** — refreshes the MaxMind GeoIP database used by `geocoder`.
- **`bin/docker-entrypoint`** — container boot script (pidfile cleanup, migrate-on-boot). Docker
  only, not for local dev.
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
