---
id: TASK-36
title: Wire bin/verify_claude_assets into overcommit pre-commit
status: Done
assignee: []
created_date: '2026-08-10 14:44'
updated_date: '2026-08-10 14:44'
labels:
  - mcp
  - tooling
  - overcommit
dependencies: []
modified_files:
  - .git-hooks/pre_commit/claude_assets.rb
  - .overcommit.yml
  - bin/verify_claude_assets
  - .claude/agents/pipeline-health-agent.md
type: chore
ordinal: 41000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Register bin/verify_claude_assets (validates .claude/skills/**/SKILL.md and .claude/agents/*.md are self-describing: required frontmatter, versioned, referenced scripts exist and parse) as an overcommit pre-commit hook, so a broken skill/agent definition blocks the commit instead of only being caught when run manually.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 ClaudeAssets pre-commit hook plugin exists and is registered in .overcommit.yml, scoped to .claude/skills/** and .claude/agents/**
- [x] #2 Hook loads without NameError/syntax error under `overcommit --list-hooks`
- [x] #3 Fault-injection test confirms the hook actually fails the commit when a skill/agent is missing required frontmatter
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added .git-hooks/pre_commit/claude_assets.rb (Overcommit::Hook::PreCommit::ClaudeAssets) running bin/verify_claude_assets, registered in .overcommit.yml under PreCommit with include filters for .claude/skills/** and .claude/agents/**. Caught and fixed a compact-class-syntax constant-lookup bug from the format-on-change hook (class A::B::C < Base couldn't resolve Base) before it shipped. Verified via `overcommit --list-hooks` (loads clean) and a live fault-injection test (stripped metadata.version from pipeline-health/SKILL.md, staged it, confirmed the hook fails the commit with the exact error, then restored). Commits: 3c00ee4 (hook + config), pushed to origin/main.
<!-- SECTION:FINAL_SUMMARY:END -->
