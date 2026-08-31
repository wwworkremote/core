<!-- ═══════════════════════════════════════════════════════════════════════
     CURRENT FOCUS  —  last updated 2026-08-30
     Cold-start resume state, canonical for every agent tool (Claude, Codex,
     Gemini, Antigravity). Whoever closes a session rewrites this whole block
     in place — step one, before the wrap-up. `git log` + Backlog are truth
     for exact SHAs / task status; if this block contradicts them, trust them
     and fix the block. Full procedure: docs/agents/session-handoff.md
     ═══════════════════════════════════════════════════════════════════════

  In flight: guided-session → datalake capture loop. Architecture is
  spec-locked (wayfinder doc-7 / ADR 010 / docs/architecture/datalake.md);
  remaining work is implementation + validation.

  Live tasks (Backlog MCP):
    TASK-112  guided recorder — HITL ACs (#3 annotate, #4 approve, #5 replay)
              need Mike at the keyboard, ideally vs a real ATS. In Progress.
    TASK-138  (High) application_research screenshot always fails —
              captureVisibleTab needs <all_urls>/activeTab. Decide the fix.
    TASK-139  (Med) execution chrome.debugger dies before the 2nd capture;
              needs a hands-on retest without Claude-in-Chrome attached.
    TASK-126  raw-asset capture — AC#4 gap tracked by 138/139; else done.

  Done 2026-08-30: first real-browser dogfood of the loop (works — see
  TASK-126 comment #2); llama3.2 RSpec flake root-fixed (TASK-111/137);
  GitHub Actions cut to one job on main (ci.yml); handoff mechanism moved
  here from CLAUDE.md so every tool sees it.

  Blocked on Mike: GitHub Actions billing (Settings → Billing & plans) —
  nothing runs in CI until cleared. No deploy mechanism exists (kamal
  unconfigured); deploy is out of scope.

  Deep handoff: ~/.config/adots/handoffs/2026-08-30-wwworkremote-guided-session.md
  (local-only, never commit).
-->

# WWWorkRemote: Agent Configuration

This file defines the capabilities, workflows, and skills configured for AI agents interacting with the WWWorkRemote repository.

## 🛠️ Engineering Skills

- **improve-codebase-architecture**: Surface architectural friction and propose deepening opportunities (seams, adapters).
- **triage**: Manage issues through a state machine (needs-triage, ready-for-agent, etc.).
- **tdd**: Test-driven development loop (red-green-refactor).
- **diagnose**: Disciplined bug diagnosis workflow.
- **to-issues**: Vertical slices from plans to independent tasks.

## ⚙️ Repository Configuration

### Resuming / closing a session
- Cold-start state = the **CURRENT FOCUS** block at the top of this file.
- Full procedure (resume + close): `docs/agents/session-handoff.md`.
- Closing = rewrite that block + commit, **before** the wrap-up summary; then write
  the deep handoff at `~/.config/adots/handoffs/` (local-only, never `git add`).

### Issue Tracker
- **Canonical**: Backlog.md via MCP (see the CRITICAL_INSTRUCTION block in `CLAUDE.md` /
  `GEMINI.md`). GitHub Issues + `gh` is the secondary/agent-facing tracker.
- **Workflow**: `to-issues` skill turns architecture plans into tasks.

### Triage Labels
- `needs-triage`
- `needs-info`
- `ready-for-agent`
- `ready-for-human`
- `wontfix`

### Domain Docs
- **Layout**: Single-context (root-based).
- **Canonical Docs**: `docs/index.md` serves as the primary map.
- **Engineering Mandates**: `CONTRIBUTING.md` (Database safety, standard wrappers, etc.).
