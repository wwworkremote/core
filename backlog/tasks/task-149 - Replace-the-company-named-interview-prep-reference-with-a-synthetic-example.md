---
id: TASK-149
title: Replace the company-named interview-prep reference with a synthetic example
status: To Do
assignee: []
created_date: '2026-09-03 19:33'
labels:
  - interview-prep
  - privacy
dependencies: []
references:
  - docs/interview-prep/basis-dsp/reference.md
  - .claude/skills/interview-prep/SKILL.md
  - .claude/agents/interview-prep-auditor.md
  - app/services/llm/interview_prep_generator/prompt_builder.rb
  - docs/interview-prep/README.md
priority: low
type: chore
ordinal: 170000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Why

`docs/interview-prep/basis-dsp/reference.md` is Mike's real interview prep for a specific, named company he is actively interviewing with. It serves two roles: (1) his actual prep material, (2) the quality-bar reference the `interview-prep-auditor` subagent diffs generated packs against, and the 7-section structure the generator's prompt builder mirrors.

For role (2) the repo only needs a *synthetic* reference pack — a fictional company, fictional role, fictional candidate history — that demonstrates the quality bar. Role (1) (Mike's real prep for real companies) should live outside the tracked repo: it is already generated to `UserJobPosting#interview_prep_pack` (DB) and exported to `~/ai/outbox/wwwr/interview-prep/<role>/`, and can also sit in the private vault.

Keeping a real, company-named, comp-discussing prep doc in the repo is the kind of specific personal content the 2026-09-03 exposure pass was clearing — it just wasn't safe to move mid-interview-process without confirming the canonical copy.

## Scope

1. Author `docs/interview-prep/_reference/reference.md` (or similar neutral path) — a fully synthetic worked example that exercises every section and the quality bar (`docs/interview-prep/basis-dsp/reference.md` is the current template; genericize it — fictional employer, role, domain primer, story arc, hooks, referral play, questions).
2. Point the tooling at the new path: `.claude/skills/interview-prep/SKILL.md`, `.claude/agents/interview-prep-auditor.md`, `CLAUDE.md`, `CONTEXT.md`, `docs/interview-prep/README.md`, `docs/architecture/interview-prep-tooling.md`, `app/services/llm/interview_prep_generator/prompt_builder.rb` (section-list reference), `spec/lib/wwwr/cli_spec.rb`.
3. Confirm Mike's real `basis-dsp` prep is preserved in the vault / `~/ai/outbox/`, then `git rm -r docs/interview-prep/basis-dsp/`.
4. Grep for `basis-dsp` / `basis_dsp` / any remaining real-company prep doc and clear.

## Notes

- Needs `SKIP=ClaudeAssets` on the commit (touches `.claude/` — TASK-142).
- Do step 3's preservation check with Mike before deleting.
<!-- SECTION:DESCRIPTION:END -->
