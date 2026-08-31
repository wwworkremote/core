<!-- ═══════════════════════════════════════════════════════════════════════
     CURRENT FOCUS  —  last updated 2026-08-31
     Cold-start resume state, canonical for every agent tool (Claude, Codex,
     Gemini, Antigravity). Whoever closes a session rewrites this whole block
     in place — step one, before the wrap-up. `git log` + Backlog are truth
     for exact SHAs / task status; if this block contradicts them, trust them
     and fix the block. Full procedure: docs/agents/session-handoff.md
     ═══════════════════════════════════════════════════════════════════════

  In flight: guided-session → datalake capture loop. Architecture is
  spec-locked (wayfinder doc-7 / ADR 010 / docs/architecture/datalake.md).
  Engine is built; needs one real supervised-application run.

  Live tasks (Backlog MCP):
    TASK-112  guided recorder — HITL ACs (#3 annotate, #4 approve, #5 replay)
              need Mike at the keyboard, ideally vs a real ATS. In Progress.
              THE blocker between "built" and "useful".
    TASK-139  (Med) execution chrome.debugger dies before the 2nd capture
              (target_closed); needs a hands-on retest without Claude-in-
              Chrome attached, then likely a SW-state-persistence fix.

  Operational state (checked 2026-08-31): job-finding half stable + running —
  dev server up, ingestion live (~49 postings/day), 12 recurring jobs
  scheduled, AI matching hourly, dashboard renders. Queue clean: 0 failed /
  0 ready (TASK-84 closed — cleared 445 macOS-sleep-pruned failed jobs).

  Done 2026-08-31: TASK-138 (research mode DOM-only, ext 1.36.1); TASK-126
  closed; TASK-84 closed.
  Done 2026-08-30: first real-browser dogfood (works); llama3.2 RSpec flake
  root-fixed (TASK-111/137); GHA cut to one job on main; handoff mechanism
  moved to AGENTS.md.

  Blocked on Mike: GitHub Actions billing (Settings → Billing & plans) —
  nothing runs in CI until cleared. No deploy mechanism exists (kamal
  unconfigured); deploy is out of scope.

  Deferred (YAGNI): first concrete Datalake::Extractor — waits for a consumer.

  DO NOT touch other repos from a wwworkremote/core session (esp. never commit
  content in the public just3ws.github.io). See memory feedback_stay_in_this_repo.

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
