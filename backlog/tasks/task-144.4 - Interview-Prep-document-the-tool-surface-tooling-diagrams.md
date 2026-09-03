---
id: TASK-144.4
title: 'Interview Prep: document the tool surface + tooling diagrams'
status: Done
assignee: []
created_date: '2026-09-03 03:28'
updated_date: '2026-09-03 03:28'
labels:
  - job-search
  - docs
dependencies: []
parent_task_id: TASK-144
priority: medium
type: docs
ordinal: 166000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Document the interview-prep tooling across every surface and add workflow/sequence/pipeline diagrams.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 bin/wwwr gains `help <command>` for per-command detail; `--help` / `-h` aliases; interview-prep help covers every flag
- [x] #2 New docs/architecture/interview-prep-tooling.md with a generation+rewrite sequence diagram, a pack-lifecycle flowchart, and the skill's audit loop -- all mermaid validated
- [x] #3 docs/agents/bin-scripts.md, README.md, docs/index.md, docs/architecture.md, CLAUDE.md all point at the tooling and diagrams
- [x] #4 Deferred surfaces (man page, shell completion) tracked in a separate task
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
`bin/wwwr help <command>` added (plus `--help` / `-h`); `interview-prep` help text covers `--regenerate` / `--spoken` / `--export[=<role>]` with doc pointers. `.rubocop_todo.yml` waives ClassLength for `lib/wwwr/cli.rb` (a flat table of thin subcommands plus help text).

`docs/architecture/interview-prep-tooling.md` (new) carries three mermaid diagrams, all validated with `mmdc`:
- a sequence diagram of generation and the read-aloud rewrite (PromptBuilder inputs → Orchestrator + guardrails → model → store → SpokenRewriter → store)
- a pack-lifecycle flowchart (human + read-aloud → page render / outbox export → external TTS tool → audio + captions + transcript)
- the skill's audit-and-grounding loop (`interview-prep-auditor` + `industry-intelligence-agent` → fold fixes → optional pressure-test → hand off)

Plus a surfaces table, a key-components table, and related-docs links. `docs/agents/bin-scripts.md`, `README.md`, `docs/index.md`, `docs/architecture.md`, and `CLAUDE.md` all updated to point at it.

Man page + shell completion deferred to TASK-146 — that is CLI-wide infra (no man/completion exists for `bin/wwwr` today), not interview-prep-specific.

Commit 5f36ec0c. 25 cli_spec examples green.
<!-- SECTION:FINAL_SUMMARY:END -->
