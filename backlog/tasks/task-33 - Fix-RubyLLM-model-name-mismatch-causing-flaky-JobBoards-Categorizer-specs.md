---
id: TASK-33
title: 'Fix RubyLLM model-name mismatch causing flaky JobBoards::Categorizer specs'
status: To Do
assignee: []
created_date: '2026-08-09 03:18'
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
- [ ] #1 Root cause identified: where the "llama3.2:latest" model name is configured (RubyLLM initializer, JobBoards::CategorizerAgent, or a model registry JSON file) versus the actual server alias ("local")
- [ ] #2 JobBoards::Categorizer and its full spec file pass reliably across at least 10 consecutive runs with different random seeds, not just once
- [ ] #3 Fix does not merely re-alias one specific value -- if the mismatch stems from a stale cached registry file, the fix addresses why it went stale and how that's prevented going forward (e.g. a refresh step, or a config that references the alias directly instead of a hardcoded upstream model name)
- [ ] #4 No regression to any other RubyLLM-dependent spec (Orchestrator, ProfileMatcher, and any other caller found during investigation)
<!-- AC:END -->
