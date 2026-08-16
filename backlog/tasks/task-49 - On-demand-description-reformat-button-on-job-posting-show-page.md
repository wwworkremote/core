---
id: TASK-49
title: On-demand description reformat button on job posting show page
status: To Do
assignee: []
created_date: '2026-08-16 12:59'
updated_date: '2026-08-16 13:33'
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
- [ ] #1 Job posting show page has a control (button) that triggers reformatting of the current posting's description on demand, not automatically
- [ ] #2 Reformat is scoped to a single JobPosting and does not block the page load -- runs as a background job (ActiveJob/SolidQueue) with a Turbo Stream update reflecting pending -> complete state, matching this app's existing turbo-rails usage
- [ ] #3 Reformatted output is stored in JobPosting#data (e.g. data["formatted_body"]), matching the existing convention for AI-derived fields (ai_category, is_remote, remote_nuance) -- body itself is never overwritten, and the raw original stays the source of truth
- [ ] #4 Show page renders data["formatted_body"] through the existing markdown() helper (already used for body and match_analysis at app/views/job_postings/show.html.erb:50) rather than inventing a new render path
- [ ] #5 New formatting agent routes through LLM::Orchestrator (like JobBoards::CategorizerAgent does), so Guardrails::Pipeline's prompt-injection/output-leak checks apply to this untrusted scraped text the same as every other LLM call site -- do not call RubyLLM directly
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Design gaps identified 2026-08-16 while filing this task (in response to user asking what was underspecified) now folded into the acceptance criteria above: storage location (data jsonb, not a new column or overwriting body), delivery mechanism (background job + Turbo Stream, not a blocking request), and guardrail routing (through LLM::Orchestrator, not a bespoke RubyLLM call). TASK-33 (the dependency) is now Done -- this task is unblocked.
<!-- SECTION:NOTES:END -->
