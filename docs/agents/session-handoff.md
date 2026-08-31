# Session handoff — pointer

This file is a **pointer**, not the handoff itself. The handoff is local-only and
lives outside the repo (it can carry cross-project / work-tenant content and must
never be committed anywhere).

## Resuming a session

A fresh agent asked to *"resume the wwworkremote guided-session capture loop from
the handoff"* should:

1. **Read the newest file in `~/.config/adots/handoffs/`** — the per-session
   handoff log, shared across Claude Code / Codex / Gemini / Antigravity. The most
   recent wwworkremote entry is named
   `YYYY-MM-DD-wwworkremote-guided-session.md`. It carries: what shipped, open
   threads with next concrete steps, and the gotchas that aren't visible from git.
2. **Check live task state in Backlog** (this repo's system of record). The
   guided-session / datalake arc is tracked under **TASK-112** (guided recorder,
   HITL ACs open), **TASK-126** (raw-asset capture), **TASK-138** / **TASK-139**
   (bugs from the first browser dogfood). Architecture is spec-locked — see
   `backlog/docs/wayfinder/doc-7 …` and `docs/architecture/datalake.md`.
3. `git log --oneline -10` for what landed last.

## Rules that outlive any one handoff

- Handoff files under `~/.config/adots/handoffs/` are **local-only — never
  `git add` them**.
- CI is a single job on push to `main` only (`.github/workflows/ci.yml`); the fast
  loop is local overcommit hooks. Don't re-expand the workflow without a reason.
- Bounded Agency: nothing fills or submits a real application without Mike's
  explicit action.
