---
id: doc-5
title: Regression Test Baseline — 2026-08-10
type: specification
created_date: '2026-08-10 12:37'
tags:
  - regression-test
  - smoke-test
  - validation
---
## Summary

Full-system validation pass covering the changes landed under milestone m-0 (task-32: hybrid search, ltree removal, RoleFamily taxonomy, role-family-driven ingestion, generalized UI filtering, weekly trend rollups) plus the earlier session's queue-starvation fix and format-on-change hook fix. This document is the baseline snapshot and the checklist for re-running the same validation later.

## Automated Checks (run these to regression-test)

```bash
# 1. Full RSpec suite (root + ingestion engine)
RAILS_ENV=test DATABASE_URL=postgres://postgres:password@localhost:5432/wwworkremote_test \
  bundle exec rspec spec packages/ingestion/spec

# 2. Repo-wide RuboCop
bundle exec rubocop

# 3. Migration parity (dev vs test)
bin/rails db:migrate:status
RAILS_ENV=test bin/rails db:migrate:status

# 4. Operational smoke test (LLM infra + ingestion sync)
# CAUTION: as of 2026-08-10, bin/verify_ingestion (called by bin/smoke) writes
# real Source rows to the TEST database outside RSpec's transactional rollback
# -- running it will pollute spec/requests/charts/data/sources_spec.rb (and
# possibly others) until those rows are manually cleaned. See task-35.
bin/smoke
```

**Baseline results (2026-08-10):**
- RSpec: 620 examples, 0 failures (confirmed clean after removing test-DB pollution left by an earlier `bin/smoke` run in this same session -- see task-35). A later full-suite re-run the same day hit 1 failure in `spec/system/llm_chat_flow_spec.rb:21` (`Ferrum::TimeoutError` on `visit new_llm_chat_path`); re-run standalone it passed 3/3 times with different seeds. Same class of headless-browser flakiness already seen in `user_pipeline_flow_spec.rb` and `job_ingestion_flow_spec.rb` (task-32.6 stash-verified as pre-existing). Not a code regression -- no action taken.
- RuboCop: 578 files inspected, no offenses.
- Migrations: dev and test both at version `2026_08_08_174429`, identical version lists.
- `bin/smoke`: LLM health/model-alias checks PASS; inference and embeddings checks FAIL (see Known Issues below — pre-existing, unrelated to task-32). Also confirmed it leaves non-rolled-back `Source` rows in the test DB (task-35).
- `bin/verify_ingestion` (part of `bin/smoke`): reports PASS, but see the test-DB-pollution caveat above.

## Live Functional Checks (manual, against the running dev server)

Routes (expect HTTP 200 on all):
- `GET /` (homepage)
- `GET /job_postings`
- `GET /job_postings?role_family=staff_plus_ic` (and any of: engineering_management, product_leadership, design_leadership, data_leadership)
- `GET /job_postings?role_family=<invalid-value>` — must return 200 with the filter silently ignored, not an error
- `GET /job_postings?q=<term>`

Backend capability checks (via `bin/rails runner`):
```ruby
JobPosting.hybrid_search("staff engineer", limit: 5) # returns relevant results, fused keyword+vector
RoleFamily.for("Staff Software Engineer")                      # => :staff_plus_ic
RoleFamily.for("Random Nonsense Title")                        # => nil
# creates N rows, N == RoleFamily.aliases_for(:staff_plus_ic).size
BoardQuery.create_for_role_family!(:staff_plus_ic, board_name: "indeed", query_params: {})
JobPostingTrendRollup.call; JobPostingTrend.count # > 0, real weekly/family-bucketed rows
```
All confirmed working against live data on 2026-08-10.

## Queue/Scheduler Health

```ruby
SolidQueue::Process.all.map { |p| [p.kind, p.last_heartbeat_at] } # all recent
SolidQueue::ReadyExecution.count # expect near-0 (backlog drained)
SolidQueue::FailedExecution.joins(:job).group("solid_queue_jobs.class_name").count
SolidQueue::RecurringTask.pluck(:key) # compare against config/recurring.yml keys
```

**Baseline (2026-08-10):** 8 processes healthy (recent heartbeats), 0 ready/pending jobs. 284 failed jobs, ALL `SolidQueue::Processes::ProcessPrunedError`/`ProcessMissingError` (worker-restart artifacts, already covered by `ApplicationJob`'s `retry_on` — not a functional regression, historical accumulation).

**Action item, not yet done:** `SolidQueue::RecurringTask` is missing `job_posting_trend_rollup` — it was added to `config/recurring.yml` today but the live Scheduler process was started before that edit and hasn't reloaded it. **Requires a SolidQueue scheduler/supervisor restart to activate** — flagged, not performed as part of this validation pass (restarting a long-running local process warranted a heads-up rather than a silent restart).

## Known Issues (pre-existing, not caused by task-32 work)

1. **task-33** — `RubyLLM::ModelNotFoundError: Unknown model "llama3.2:latest"`, intermittent (order-dependent) failures in `JobBoards::Categorizer` specs. Root cause not yet found; confirmed unrelated to task-32.
2. **task-34** — `OLLAMA_API_BASE` points at port 11500 (chat model, no `--embeddings`) instead of port 11501 (the actual embeddings-capable server). Masked in specs by a global stub; breaks live (non-test) embedding generation. `bin/smoke`'s inference-timeout failure was found in the same pass and may or may not share a root cause with task-33 -- noted as an open question on task-34.
3. **task-35** — `bin/verify_ingestion`/`bin/smoke` write real, non-transactional `Source` rows into the TEST database, which then break `spec/requests/charts/data/sources_spec.rb`'s exact-count assertion. Root cause confirmed directly (not inferred) during this pass; the 2 stray rows were manually deleted to unblock this commit. Was flagged as a known instability as far back as 2026-05-23 (doc-1) under a task that was later archived without being fixed -- filed properly now. **Anyone running `bin/smoke` against RAILS_ENV=test should expect to need the same cleanup until task-35 lands.**

## Scope Note

This baseline validates the *system as changed this session* (task-32's six subtasks, the GeocodingJob queue-starvation fix, the format-on-change hook fix). It is not an exhaustive audit of every feature in the app (e.g. resume matching, interview pipeline, admin panels were not individually smoke-tested here) -- the automated RSpec suite is the actual regression backstop for those; this document's live checks are targeted at what changed.
