---
id: TASK-13
title: 'Fix stale llama.cpp endpoint (:8080 -> :11500)'
status: Done
assignee: []
created_date: '2026-07-27 17:27'
updated_date: '2026-07-27 17:36'
labels: []
dependencies: []
references:
  - config/initializers/00_ruby_llm.rb
  - docker-compose.yml
  - docs/development.md
priority: high
ordinal: 13000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
llama.cpp now serves at http://127.0.0.1:11500 per agent-guide, but the app hardcoded :8080 in many places (initializer, docker-compose, docs, app-level fallback defaults in profile_embedder/job_boards embedder/verify_llm/live spec, VCR cassettes, and WebMock stubs), breaking local-first AI inference. Fixing all of it for consistency, not just the initializer, since .env and the fallback defaults would otherwise silently override the initializer fix.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 config/initializers/00_ruby_llm.rb openai_api_base/ollama_api_base default updated to :11500
- [ ] #2 docker-compose.yml OLLAMA_API_BASE default updated to :11500
- [ ] #3 docs/development.md prerequisites section updated to reference :11500
- [ ] #4 config/initializers/00_ruby_llm.rb defaults updated to :11500
- [ ] #5 .env OLLAMA_API_BASE updated to :11500 (active local override)
- [ ] #6 docker-compose.yml OLLAMA_API_BASE updated to :11500
- [ ] #7 docs/development.md, CONTRIBUTING.md, docs/configuration.md, docs/troubleshooting.md, docs/architecture/ruby_llm.md updated to :11500
- [ ] #8 app/services/resume/profile_embedder.rb and packages/ingestion/app/services/job_boards/embedder.rb fallback defaults updated to :11500
- [ ] #9 bin/verify_llm.rb and spec/integration/llm_live_spec.rb fallback defaults updated to :11500
- [ ] #10 VCR cassettes and WebMock stub_request URLs updated to :11500 so the suite stays green
- [ ] #11 bundle exec rspec passes
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Widened scope beyond the original 3 files: also fixed hardcoded :8080 fallback defaults in app/services/resume/profile_embedder.rb, packages/ingestion/app/services/job_boards/embedder.rb, bin/verify_llm.rb, spec/integration/llm_live_spec.rb; the active .env override; docs (CONTRIBUTING.md, docs/configuration.md, docs/troubleshooting.md, docs/architecture/ruby_llm.md); and VCR cassettes + WebMock stub_request URLs in specs, since leaving those at 8080 would have broken the suite once the code defaulted to 11500. Also discovered bundle was never installed under the pinned ruby 4.0.2 build -- ran 'bundle install' to unblock verification (separate from TASK-16's version bump).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
llama.cpp endpoint migrated from :8080 to :11500 across all application code, config, docs, and specs. Full rspec suite: 241 examples, 3 pre-existing failures unrelated to this change (tracked separately as TASK-11 and TASK-12).
<!-- SECTION:FINAL_SUMMARY:END -->
