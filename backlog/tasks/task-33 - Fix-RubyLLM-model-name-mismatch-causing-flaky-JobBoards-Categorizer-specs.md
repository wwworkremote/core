---
id: TASK-33
title: 'Fix RubyLLM model-name mismatch causing flaky JobBoards::Categorizer specs'
status: Done
assignee: []
created_date: '2026-08-09 03:18'
updated_date: '2026-08-16 13:22'
labels: []
dependencies: []
references:
  - packages/ingestion/spec/services/job_boards/categorizer_spec.rb
  - packages/ingestion/app/services/job_boards/categorizer.rb
priority: medium
type: bug
ordinal: 38000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Discovered while finalizing task-32.6 (2026-08-08): `JobBoards::Categorizer#call` and 3 related specs in `packages/ingestion/spec/services/job_boards/categorizer_spec.rb` intermittently fail with:

```
RubyLLM::ModelNotFoundError: Unknown model: "llama3.2:latest". If the model exists at the provider, refresh the registry with `RubyLLM.models.refresh!` and persist it with `RubyLLM.models.save_to_json`. Rails model registries can call `Model.refresh!` instead.
```

Confirmed the local LLM backend itself is healthy -- `llama-server` is running on `127.0.0.1:11500` and responds to `GET /v1/models` with a model aliased `"local"`, not `"llama3.2:latest"`. So this is a stale/mismatched entry somewhere in RubyLLM's model registry or in wherever `JobBoards::CategorizerAgent` (or its RubyLLM chat configuration) specifies the model name -- it's asking RubyLLM for a model id the actual server was never configured to serve under.

Failure is intermittent, not deterministic on every run -- it depends on RSpec's random seed/execution order, which points to registry state being lazily loaded/cached once per test process and only failing when the Categorizer spec happens to run before whatever (if anything) warms or refreshes the registry correctly. Reproduced twice with `bundle exec rspec spec packages/ingestion/spec` using specific seeds; a plain rerun with a different seed often passes.

Confirmed NOT caused by any of the task-32 (Postgres capability upgrades) changes -- `JobBoards::Categorizer`, `JobBoards::CategorizerAgent`, and RubyLLM configuration were untouched by that work.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Root cause identified: where the "llama3.2:latest" model name is configured (RubyLLM initializer, JobBoards::CategorizerAgent, or a model registry JSON file) versus the actual server alias ("local")
- [x] #2 JobBoards::Categorizer and its full spec file pass reliably across at least 10 consecutive runs with different random seeds, not just once
- [x] #3 Fix does not merely re-alias one specific value -- if the mismatch stems from a stale cached registry file, the fix addresses why it went stale and how that's prevented going forward (e.g. a refresh step, or a config that references the alias directly instead of a hardcoded upstream model name)
- [x] #4 No regression to any other RubyLLM-dependent spec (Orchestrator, ProfileMatcher, and any other caller found during investigation)
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Investigated live and found this was already fixed, just never closed out. `config/models.yml`'s `defaults.primary` has been `"local"` (matching the real llama.cpp server alias) since commit 393f42fe (2026-05-06) -- three months before this task was even filed, and it never held `"llama3.2:latest"` at any point in git history. The literal string `"llama3.2:latest"` only exists as arbitrary placeholder test data in spec factories/cassettes/system specs (spec/factories/models.rb, VCR cassettes, selector_learner_agent_spec, llm_chat_flow_spec) -- none of it wired to the actual default-model resolution path.

`packages/ingestion/spec/services/job_boards/categorizer_spec.rb` already resolves its test model dynamically via `let(:model_id) { LLM::Registry.default_model_id }` + `find_or_create_by!`, exactly the "reference the alias directly instead of a hardcoded upstream model name" fix AC #3 asked for. `spec/rails_helper.rb`'s `before(:suite)` calls `LLM::Registry.sync` once for the whole run, so the DB-backed `Model` row is always in sync with `config/models.yml`.

Verified live: ran the full RubyLLM-dependent spec set (categorizer_spec, registry_spec, orchestrator_spec, profile_matcher_spec, company_auditor_spec, selector_learner_agent_spec -- 25 examples) across 10 distinct random seeds. 0 failures on every run, including seeds that reproduce the intentional "LLM call fails" test paths (Connection refused / API server error logged as expected, not treated as spec failures). No hardcoded "llama3.2:latest" anywhere in app code (confirmed via full-repo grep, non-spec files only).
<!-- SECTION:FINAL_SUMMARY:END -->
