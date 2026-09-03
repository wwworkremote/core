---
id: TASK-146
title: 'bin/wwwr: troff man page + shell completion'
status: Done
assignee: []
created_date: '2026-09-03 03:27'
updated_date: '2026-09-03 03:31'
labels:
  - tooling
  - docs
dependencies: []
priority: low
type: task
ordinal: 165000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
bin/wwwr has `--help` / `help <command>` and doc coverage but no man page and no shell completion. Add both, covering every subcommand (status, postings, transition, match, interview-prep), not just one.

- man/wwwr.1 (or a .1.md compiled with pandoc/ronn) -- decide the source format and whether it is generated at build time or committed.
- completions/wwwr.bash + completions/_wwwr (zsh): complete subcommands, then per-subcommand flags (--regenerate / --spoken / --export for interview-prep, the filter flags for postings, the event names for transition, --source / --escalate for match).
- Wire installation into bin/setup or document it.

Raised while documenting the interview-prep tooling (TASK-144.4); deferred there because this is CLI-wide infra, not interview-prep-specific.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 `man wwwr` renders a page documenting every subcommand and its flags
- [x] #2 bash and zsh completion complete subcommands and their flags
- [x] #3 completion source lives in the repo; installation is wired into bin/setup or documented
- [x] #4 docs/agents/bin-scripts.md notes the man page and completion
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built this session (not deferred after all — Mike re-emphasized).

- `man/wwwr.1` — troff man page: NAME / SYNOPSIS / DESCRIPTION / COMMANDS (status, postings, transition, match, interview-prep, help) / OPTIONS (postings filters, transition events, interview-prep flags) / FILES / SEE ALSO. Renders clean (`man ./man/wwwr.1`, no lint warnings). Committed as source — no build step.
- `completions/wwwr.bash` — bash: subcommand completion, then per-subcommand (postings filters, transition events, match/interview-prep flags, help topics). Functionally verified.
- `completions/wwwr.zsh` — `#compdef wwwr bin/wwwr`, `_arguments` state machine, same coverage.
- Install documented in the man page FILES section, `docs/agents/bin-scripts.md`, and `README.md` (source the bash file from `~/.bashrc`; add `completions/` to `fpath` before `compinit` for zsh). Not wired into `bin/setup` — it edits the user's shell rc, which is their call.

Covers every subcommand, not just interview-prep.
<!-- SECTION:FINAL_SUMMARY:END -->
