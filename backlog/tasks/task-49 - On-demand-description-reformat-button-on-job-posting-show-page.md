---
id: TASK-49
title: On-demand description reformat button on job posting show page
status: Done
assignee: []
created_date: '2026-08-16 12:59'
updated_date: '2026-08-16 14:25'
labels: []
dependencies:
  - TASK-33
references:
  - app/controllers/job_postings_controller.rb
  - app/views/job_postings/show.html.erb
priority: medium
type: feature
ordinal: 55000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
On `/job_postings/:id` (app/views/job_postings/show.html.erb), add a button that lets the user trigger an on-demand LLM reformat of the posting's description/body into something more readable -- raw scraped descriptions are often a wall of unformatted text (see the recent 6069f50 fix that stopped the extension from flattening descriptions to one line; this is the natural next step: cleaning up what's already there on request, not changing how it's captured).

Not auto-run on every posting (cost/latency) -- explicitly user-triggered, single posting at a time.

Sequenced after TASK-33 (RubyLLM model-registry flakiness) since this feature adds a new RubyLLM call path -- want the registry issue root-caused first rather than building on top of a known-flaky LLM call pattern.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Job posting show page has a control (button) that triggers reformatting of the current posting's description on demand, not automatically
- [x] #2 Reformat is scoped to a single JobPosting and does not block the page load -- runs as a background job (ActiveJob/SolidQueue) with a Turbo Stream update reflecting pending -> complete state, matching this app's existing turbo-rails usage
- [x] #3 Reformatted output is stored in JobPosting#data (e.g. data["formatted_body"]), matching the existing convention for AI-derived fields (ai_category, is_remote, remote_nuance) -- body itself is never overwritten, and the raw original stays the source of truth
- [x] #4 Show page renders data["formatted_body"] through the existing markdown() helper (already used for body and match_analysis at app/views/job_postings/show.html.erb:50) rather than inventing a new render path
- [x] #5 New formatting agent routes through LLM::Orchestrator (like JobBoards::CategorizerAgent does), so Guardrails::Pipeline's prompt-injection/output-leak checks apply to this untrusted scraped text the same as every other LLM call site -- do not call RubyLLM directly
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Design gaps identified 2026-08-16 while filing this task (in response to user asking what was underspecified) now folded into the acceptance criteria above: storage location (data jsonb, not a new column or overwriting body), delivery mechanism (background job + Turbo Stream, not a blocking request), and guardrail routing (through LLM::Orchestrator, not a bespoke RubyLLM call). TASK-33 (the dependency) is now Done -- this task is unblocked.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built and verified live against a real job posting (id 5436, real scraped body from an Affirm posting), not just via specs:

- `app/agents/job_boards/reformatter_agent.rb` -- routes through `LLM::Orchestrator` (Guardrails::Pipeline applies), mirrors `JobBoards::CategorizerAgent`'s shape.
- `app/prompts/job_boards/reformatter_agent/instructions.txt.erb` -- admin-editable via `PipelinePrompt` (key `job_boards_reformatter`, added to `KNOWN_KEYS`).
- `app/services/job_boards/reformatter.rb` -- applies the agent's output to `data["formatted_body"]`, clears the `data["reformatting"]` pending flag in an `ensure` so a failed LLM call never leaves the UI stuck showing a spinner.
- `app/jobs/job_posting_reformat_job.rb` -- background job, broadcasts a Turbo Stream replace of the description partial when done.
- `JobPostingsController#reformat` (POST /job_postings/:id/reformat) -- marks pending, enqueues the job, returns an immediate turbo_stream response so the button becomes a spinner without waiting on the LLM call.
- `app/views/job_postings/_description.html.erb` + `show.html.erb` -- extracted the description block into a `dom_id`-targeted partial, subscribed via `turbo_stream_from @job_posting`. Prefers `data["formatted_body"]` over raw `body` when present, both rendered through the existing `markdown()` helper.
- `JobPosting#reformatting?` -- reads the transient `data["reformatting"]` flag.

Verified live: curl-fetched the real rendered page and confirmed the button markup; ran `JobBoards::Reformatter` directly against job posting 5436's real body through the actual local LLM server -- got back clean, well-structured Markdown. Confirmed via raw SQL (`data->>'formatted_body'`) that the Postgres jsonb round-trip is exact (matches the ActiveRecord-loaded value byte for byte), valid UTF-8, `body` column completely untouched, and all pre-existing `data` keys (ai_category, is_remote, etc.) survived the merge undisturbed.

60 examples across 4 new/modified spec files (reformatter_spec, job_posting_reformat_job_spec, job_posting_spec, job_postings request spec) + the existing categorizer_spec (regression check on the shared Orchestrator path) all pass. RuboCop and erb_lint clean on every touched file. Browser-based visual verification was not possible (Chrome automation doesn't reach this environment -- same known limitation `bin/verify_promote.rb` exists to work around); curl + direct DB inspection substituted as the live-verification method instead.

Not yet committed -- pending explicit go-ahead.
<!-- SECTION:FINAL_SUMMARY:END -->
