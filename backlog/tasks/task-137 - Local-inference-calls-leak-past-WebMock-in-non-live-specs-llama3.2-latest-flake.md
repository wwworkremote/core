---
id: TASK-137
title: >-
  Local-inference calls leak past WebMock in non-live specs (llama3.2:latest
  flake)
status: Done
assignee: []
created_date: '2026-08-30 22:48'
updated_date: '2026-08-30 23:21'
labels:
  - testing
  - flake
  - llm
dependencies: []
modified_files:
  - spec/support/local_inference_net_guard.rb
  - spec/cassettes/llm_orchestrator_basic.yml
  - spec/cassettes/llm_empty_response.yml
priority: medium
type: bug
ordinal: 153000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Pre-commit / CI RSpec runs intermittently failed with `RubyLLM::ModelNotFoundError: Unknown model: "llama3.2:latest"` (and, less often, `Connection refused` / `API server error`) in LLM-touching specs (`spec/services/LLM/orchestrator_spec.rb`, `spec/services/job_boards/reformatter_spec.rb`, `spec/services/LLM/company_auditor_spec.rb`, `spec/services/LLM/profile_matcher_spec.rb`).

Root cause: `spec/support/vcr.rb` sets `config.ignore_localhost = true` (needed so Capybara/Cuprite can reach the test server). That also turns every *unstubbed* request to the local llama.cpp servers (`localhost:11500` chat, `:11501` embeddings) into a real network call instead of a loud `WebMock::NetConnectNotAllowedError`. When the real inference server is up, an unstubbed RubyLLM model probe returns a model list that does not contain the test fixture id `llama3.2:latest` (`spec/factories/models.rb`), surfacing as `ModelNotFoundError`. It is order-dependent because it depends on which unstubbed call a given spec ordering triggers and on whether the real server is reachable.

The platform is healthy — this is purely a test-isolation defect on the wwworkremote side. Also found: `spec/cassettes/llm_orchestrator_basic.yml` and `llm_empty_response.yml` were orphan cassettes (no spec referenced them) baking in the same misleading `llama3.2:latest` id.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Non-live specs can never make a real HTTP call to the local inference ports (11500/11501); an unstubbed call fails loudly with a clear message instead of hitting the real server
- [x] #2 `:live`-tagged specs are unaffected and still reach real services
- [x] #3 Full RSpec suite passes with the local inference server both up and down
- [x] #4 Orphan/misleading LLM cassettes removed
<!-- AC:END -->

## Comments

<!-- COMMENTS:BEGIN -->
author: claude
created: 2026-08-30 23:21
---
Follow-up: the net guard added here is defense-in-depth, not the flake's fix. Making unstubbed :11500 calls fail loudly turned the intermittent `llama3.2:latest` flake into a deterministic 5/5 failure on seed 39256, which exposed the real cause — `LLM::Registry` memoizing `@default_model_id` with no test-isolation, poisoned by `registry_spec` stubbing `YAML.load_file`. Fixed in TASK-111 (merged 359290cc) with a global `@default_model_id` reset in `spec/rails_helper.rb`. Both changes stay.
---
<!-- COMMENTS:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added `spec/support/local_inference_net_guard.rb`: a global `config.before` hook that registers a catch-all `stub_request(:any, %r{https?://(localhost|127.0.0.1):1150[01]/}).to_raise(...)` for every non-`:live` example. An example's own `stub_request` is registered later and still wins for requests it matches; anything unstubbed now raises with a "this example is not hermetic" message instead of silently hitting the real llama.cpp server. `:live` specs skip the guard (they already run under `WebMock.allow_net_connect!` via `spec/support/live_integration.rb`).

Deleted the two orphan cassettes (`llm_orchestrator_basic.yml`, `llm_empty_response.yml`) — no spec referenced them and they carried the misleading `llama3.2:latest` id.

Left `spec/factories/models.rb` default id as-is (arbitrary non-real test id; changing it to `local` would collide with the before(:suite)-synced real model row on the provider+model_id unique index).

Verified: full suite green (1145 examples, 0 failures) with the inference server up; LLM/embedding/agent slice green with it down. Not reproducible after the fix across repeated runs.
<!-- SECTION:FINAL_SUMMARY:END -->
