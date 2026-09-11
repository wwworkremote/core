---
id: TASK-144.2
title: >-
  Interview Prep: interview-prep skill + interview-prep-auditor agent + bin/wwwr
  entry
status: Done
assignee: []
created_date: '2026-09-02 19:22'
updated_date: '2026-09-02 19:26'
labels:
  - job-search
  - llm
  - tooling
dependencies: []
parent_task_id: TASK-144
priority: high
type: enhancement
ordinal: 163000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Package the interview-prep-pack workflow into the repo's skills + agents layer, mirroring indeed-profile-sync skill + indeed-profile-auditor agent.

- bin/wwwr interview-prep <job_posting_id> [--regenerate]: CLI entry (Wwwr::InterviewPrep in lib/wwwr/), prints the stored pack, regenerates on demand. Mirrors bin/wwwr match.
- .claude/skills/interview-prep/SKILL.md: model-invoked skill. Workflow: locate posting + interview context -> generate via bin/wwwr -> dispatch interview-prep-auditor for a quality punch list -> dispatch industry-intelligence-agent to verify the domain primer's facts / acronym-authority bindings / learning links against real current sources -> fold fixes back into the pack -> optionally career-coach-agent (story) and hiring-manager-agent / recruiter-agent (pressure-test likely questions) -> hand Mike the sharpened pack + residual judgement calls.
- .claude/agents/interview-prep-auditor.md: read-only agent, mirror of indeed-profile-auditor. Input: a generated pack. Diffs against the quality bar (docs/interview-prep/_reference/reference.md) + the posting requirements. Punch list: generic-vs-real domain primer, hallucinated links, unbound acronyms, missing must-know concepts, skill-gap/blind-spot confusion, story grounded in real history or not. Split mechanical vs judgement.
- Register in CLAUDE.md Agent skills section (like the Indeed entry).

All rules files: expressive GitHub-flavored extended Markdown, YAML frontmatter mandatory.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 bin/wwwr interview-prep <id> prints the stored pack; --regenerate forces a fresh generation; unknown id reports without raising
- [x] #2 Wwwr::InterviewPrep has a spec; cli_spec.rb has an interview-prep describe block
- [x] #3 .claude/skills/interview-prep/SKILL.md exists with valid YAML frontmatter (name, description with trigger branches, metadata.version) and the orchestration workflow
- [x] #4 .claude/agents/interview-prep-auditor.md exists with valid frontmatter (name, description, tools, model, metadata.version) and read-only audit instructions
- [x] #5 The skill dispatches interview-prep-auditor and industry-intelligence-agent as described
- [x] #6 CLAUDE.md Agent skills section registers the skill
- [x] #7 Rules files use expressive GFM (tables, task lists, alert callouts, fenced code) per the standing style rule
- [x] #8 Existing wwwr cli_spec + interview-prep specs stay green
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
bin/wwwr interview-prep 7068 verified live against the real Basis posting -- prints the stored pack. Skill shows in the available-skills list after write.

Commit used SKIP=ClaudeAssets per the TASK-142 handoff note (ClaudeAssets pre-commit hook broken on .claude/ commits).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Packaged the interview-prep-pack workflow into the skills + agents layer, mirroring `indeed-profile-sync` + `indeed-profile-auditor`.

**`bin/wwwr interview-prep <job_posting_id> [--regenerate]`** — `Wwwr::InterviewPrep` (lib/wwwr/), prints the stored pack or generates one via `LLM::InterviewPrepGenerator`. Wired into `Wwwr::CLI` COMMANDS + usage + `bin/wwwr` requires. 6 new cli_spec examples (stored / regenerate / new / failure / 404); 33 in the touched specs green.

**`.claude/skills/interview-prep/SKILL.md`** — model-invoked (description carries three trigger branches: scheduled interview, sharpen/regenerate/fact-check an existing pack, ground the primer). 7-step workflow: locate posting + context → `bin/wwwr interview-prep --regenerate` → dispatch `interview-prep-auditor` → dispatch `industry-intelligence-agent` to verify primer concepts / acronym-to-authority citations / learning links → optional `career-coach-agent` + `hiring-manager-agent` + `recruiter-agent` pressure-test → fold mechanical fixes in, leave judgement calls → hand off. Closes with the known local-model failure modes.

**`.claude/agents/interview-prep-auditor.md`** — read-only (Bash/Read/Grep/Glob, sonnet). Pulls the pack + posting + quality bar (`docs/interview-prep/_reference/reference.md`), diffs section-by-section via a checks table, classifies every finding mechanical vs judgement, reports a ranked punch list + "what's clean". Explicitly hunts stack-as-domain, skill-gap-as-blind-spot, and invented links.

**`CLAUDE.md`** — "Prepping for an interview" entry in the Agent skills section.

Both rules files: YAML frontmatter + expressive GFM (tables, task lists, `> [!NOTE]`/`> [!IMPORTANT]` callouts, fenced code) per the standing style rule. Frontmatter validated (`YAML.safe_load`). Committed with `SKIP=ClaudeAssets` (TASK-142). Commit ea01f577.
<!-- SECTION:FINAL_SUMMARY:END -->
