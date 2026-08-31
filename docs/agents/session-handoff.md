# Session handoff — how to resume, how to close

## Resuming

1. **Read the `CURRENT FOCUS` block at the top of `CLAUDE.md`.** It is injected into
   every session in this repo — you have already seen it. It names what's in flight,
   the live Backlog task IDs, and what's blocked on Mike. That is the fast path.

2. **Open the deep handoff** named in that block:
   `~/.config/adots/handoffs/2026-08-30-wwworkremote-guided-session.md`
   (a later session may have written a newer `…-wwworkremote-guided-session.md` —
   the `CURRENT FOCUS` block always names the current one). It carries the
   per-thread next steps and the gotchas that aren't visible from git. This file is
   **local-only** — it can hold cross-project content and must never be committed.

3. **Reconcile with reality** — `git log --oneline -10` and the Backlog task views.
   If the `CURRENT FOCUS` block disagrees with git/Backlog, git/Backlog win; fix the
   block.

## Closing a session (do this before you wrap up)

1. **Rewrite the `CURRENT FOCUS` block in `CLAUDE.md` in place** — the whole block:
   the date, the `main @ <sha>`, what's in flight, the live task IDs with one line
   each, what's done, what's blocked on Mike. Keep it tight (~25 lines). Commit it
   with your other changes. This is the thing a cold agent cannot miss.
2. **Write / append the deep handoff** at
   `~/.config/adots/handoffs/YYYY-MM-DD-wwworkremote-guided-session.md` — full
   detail, next concrete step per open thread, gotchas. **Never `git add` it.**
   Point the `CURRENT FOCUS` block at it by exact filename.
3. Confirm everything is committed and pushed; state the `main` sha.

## Rules that outlive any one handoff

- Handoff files under `~/.config/adots/handoffs/` are **local-only — never `git add`**.
- CI is one job on push to `main` only (`.github/workflows/ci.yml`); the fast loop is
  local overcommit hooks. Don't re-expand the workflow without a reason.
- Bounded Agency: nothing fills or submits a real application without Mike's explicit action.
- Architecture for the guided-session / datalake arc is spec-locked — `wayfinder doc-7`,
  `ADR 010`, `docs/architecture/datalake.md`. Implementation proceeds as normal Backlog work.
