---
id: TASK-144.2
title: >-
  Interview Prep: interview-prep skill + interview-prep-auditor agent + bin/wwwr
  entry
status: In Progress
assignee: []
created_date: '2026-09-02 19:22'
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
- .claude/agents/interview-prep-auditor.md: read-only agent, mirror of indeed-profile-auditor. Input: a generated pack. Diffs against the quality bar (docs/research/interview-prep-basis-dsp.md) + the posting requirements. Punch list: generic-vs-real domain primer, hallucinated links, unbound acronyms, missing must-know concepts, skill-gap/blind-spot confusion, story grounded in real history or not. Split mechanical vs judgement.
- Register in CLAUDE.md Agent skills section (like the Indeed entry).

All rules files: expressive GitHub-flavored extended Markdown, YAML frontmatter mandatory.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 bin/wwwr interview-prep <id> prints the stored pack; --regenerate forces a fresh generation; unknown id reports without raising
- [ ] #2 Wwwr::InterviewPrep has a spec; cli_spec.rb has an interview-prep describe block
- [ ] #3 .claude/skills/interview-prep/SKILL.md exists with valid YAML frontmatter (name, description with trigger branches, metadata.version) and the orchestration workflow
- [ ] #4 .claude/agents/interview-prep-auditor.md exists with valid frontmatter (name, description, tools, model, metadata.version) and read-only audit instructions
- [ ] #5 The skill dispatches interview-prep-auditor and industry-intelligence-agent as described
- [ ] #6 CLAUDE.md Agent skills section registers the skill
- [ ] #7 Rules files use expressive GFM (tables, task lists, alert callouts, fenced code) per the standing style rule
- [ ] #8 Existing wwwr cli_spec + interview-prep specs stay green
<!-- AC:END -->
