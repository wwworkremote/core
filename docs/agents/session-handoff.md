# Session handoff — how to resume, how to close

The **CURRENT FOCUS** block at the top of **`AGENTS.md`** is the cold-start resume
state. It is the canonical location for every agent tool — `CLAUDE.md` and
`GEMINI.md` each open with a one-line pointer to it, so whichever file your tool
loads on start, you land on the same block. Keeping the state in one file (not
three) is deliberate: three copies rot.

## Resuming

1. **Read the CURRENT FOCUS block in `AGENTS.md`.** Whatever tool you are, you have
   already seen either it or the pointer to it. It names what's in flight, the live
   Backlog task IDs, and what's blocked on Mike. That is the fast path.

2. **Open the deep handoff** named in that block:
   `~/.config/adots/handoffs/YYYY-MM-DD-wwworkremote-guided-session.md` — the
   per-thread next steps and the gotchas that aren't visible from git. The block
   names the current file by exact path; don't guess "the newest one" (another
   tool's session close can bump a different file to the top). This file is
   **local-only** and must never be committed.

3. **Reconcile with reality** — `git log --oneline -10` and the Backlog task views.
   If the block disagrees with git/Backlog, git/Backlog win; fix the block.

## Closing a session (do this FIRST, before the wrap-up summary)

1. **Rewrite the CURRENT FOCUS block in `AGENTS.md` in place** — the whole block:
   date, what's in flight (2-3 lines), the live task IDs one line each, what's done
   recently, what's blocked on Mike, and the exact path to the deep handoff. Keep it
   ~25 lines. Commit it with your other changes. `CLAUDE.md` / `GEMINI.md` only
   carry the pointer — don't duplicate the state into them.
2. **Write / append the deep handoff** at
   `~/.config/adots/handoffs/YYYY-MM-DD-wwworkremote-guided-session.md` — full
   detail, next concrete step per open thread, gotchas. **Never `git add` it.**
3. Confirm everything is committed and pushed; state the `main` SHA.

## Rules that outlive any one handoff

- Handoff files under `~/.config/adots/handoffs/` are **local-only — never `git add`**.
- CI is one job on push to `main` only (`.github/workflows/ci.yml`); the fast loop is
  local overcommit hooks. Don't re-expand the workflow without a reason.
- Bounded Agency: nothing fills or submits a real application without Mike's explicit action.
- Architecture for the guided-session / datalake arc is spec-locked — `wayfinder doc-7`,
  `ADR 010`, `docs/architecture/datalake.md`. Implementation proceeds as normal Backlog work.
