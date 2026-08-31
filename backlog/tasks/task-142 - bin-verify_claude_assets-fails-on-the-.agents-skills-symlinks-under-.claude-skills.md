---
id: TASK-142
title: >-
  bin/verify_claude_assets fails on the .agents/skills symlinks under
  .claude/skills/
status: To Do
assignee: []
created_date: '2026-08-31 21:43'
labels:
  - dev-env
dependencies: []
priority: low
type: bug
ordinal: 158000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Symptom

`ruby bin/verify_claude_assets` fails on `main` with 37 errors, all `skill '<name>': missing metadata.version` — for `ask-matt`, `wayfinder`, `tdd`, `triage`, `grilling`, `research`, `code-review`, etc. The `ClaudeAssets` Overcommit pre-commit hook (`.overcommit.yml`, `include: .claude/skills/**/*` + `.claude/agents/**/*`) therefore blocks any commit that touches `.claude/skills/` or `.claude/agents/`.

## Root cause

`.claude/skills/` contains ~38 **symlinks** into `../../.agents/skills/*` (e.g. `.claude/skills/tdd -> ../../.agents/skills/tdd`), added 2026-08-26. `bin/verify_claude_assets` does `Dir.glob('.claude/skills/*/SKILL.md')`, which follows the symlinks into the vendored `.agents/skills` set — and those skills don't carry this repo's `metadata.version` frontmatter convention. Only 4 skills are real repo dirs: `backlog-audit`, `direct-hiring-board-verify`, `pipeline-health`, `indeed-profile-sync`.

The hook has been dormant since it was wired (`3c00ee42`) because nothing committed a `.claude/` asset change until `cfaf1f45` (indeed-profile-sync), which had to `SKIP=ClaudeAssets`.

## Decision needed

Either the validator should skip symlinked skill dirs (validate only this repo's own assets — one `File.symlink?` guard), or the `.agents/skills` set should get `metadata.version` frontmatter so the symlinked skills validate too. The first is a smaller change; the second matches "every invocable skill is self-describing" if that's the actual intent.

## Acceptance

- [ ] `ruby bin/verify_claude_assets` passes on a clean checkout
- [ ] A commit touching `.claude/skills/` no longer needs `SKIP=ClaudeAssets`
<!-- SECTION:DESCRIPTION:END -->
