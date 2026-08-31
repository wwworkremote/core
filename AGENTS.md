<!-- ═══════════════════════════════════════════════════════════════════════
     CURRENT FOCUS  —  last updated 2026-08-31 (session 2)
     Cold-start resume state, canonical for every agent tool (Claude, Codex,
     Gemini, Antigravity). Whoever closes a session rewrites this whole block
     in place — step one, before the wrap-up. `git log` + Backlog are truth
     for exact SHAs / task status; if this block contradicts them, trust them
     and fix the block. Full procedure: docs/agents/session-handoff.md
     ═══════════════════════════════════════════════════════════════════════

  In flight: guided-session → datalake capture loop. Architecture is
  spec-locked (wayfinder doc-7 / ADR 010 / docs/architecture/datalake.md).
  Engine is built; entry points now wired (top-nav + inline URL form, this
  session). Still needs one real supervised-application run.

  Live tasks (Backlog MCP):
    TASK-112  guided recorder — HITL ACs (#3 annotate, #4 approve, #5 replay)
              need Mike at the keyboard, ideally vs a real ATS. In Progress.
              THE blocker between "built" and "useful". Mike attempted a
              dogfood this session; blocked by TASK-141 (server wedge).
    TASK-141  (High, In Progress) dev web service com.wwworkremote.web wedges
              silently — puma holds the socket but stops answering; launchd
              KeepAlive + puma worker_timeout both blind to it. MITIGATED:
              cluster mode (8f76b536) + WebHealthWatchdogJob every-minute
              recovery (fb6825a1). Root cause still open (nio4r / ActionCable-
              in-puma / Ruby 4.0; a 60s malformed GET /cable; why the debug
              gem session is active at all). Full trail: task comments.
    TASK-139  (Med) execution chrome.debugger dies before the 2nd capture
              (target_closed); needs a hands-on retest without Claude-in-
              Chrome attached, then likely a SW-state-persistence fix.

  Operational state (verified 2026-08-31 session 2): dev server up (200),
  now runs puma cluster mode (master + 1 worker) via bin/wwworkremote-web,
  with the watchdog recurring job self-healing wedges in ~2-3 min. Ingestion
  live, 13 recurring jobs scheduled (watchdog added), AI matching hourly,
  dashboard renders. Build fingerprint now visible in the page footer.

  Done 2026-08-31 session 2 (pushed, main @ 36365d81):
    - guided sessions: promoted to top nav + inline paste-URL start form
    - build stamp (git SHA + date + env) in every page footer
    - docs/applying-with-the-harness.md — operator runbook, posting link →
      submitted application, marks automated vs by-hand vs not-built
    - TASK-141 filed, diagnosed (thread dump), mitigated (cluster + watchdog)
    - CI REMOVED — deleted .github/workflows/ci.yml + bin/ci (GHA billing
      disabled, solo project). Checks = overcommit hooks + a manual full-suite
      run before risky changes (docs/testing.md). No CI service exists.
  Done 2026-08-31 session 1: TASK-138 / TASK-126 / TASK-84 closed; TASK-140
  filed.

  External (NOT repo work, no artifact here): Indeed profile — full pass done
  via Claude-in-Chrome, now in good shape. 15-entry work history deduped +
  titles/dates aligned to the just3ws canonical resume (bullets filled from
  canonical highlights); ActiveCampaign + Tandem added; current role company
  "Independent" → "Self-employed"; summary replaced with the new archetype
  resume's version. Preferences: the comp floor, Remote+Hybrid+In-person,
  work-area categories fixed, blue-collar "work schedule" pref deleted. Skills
  curated 178 → 49. Old "0 to 1" resume deleted; Mike uploaded the Principal
  Systems Architect archetype PDF; sync-suggestions reviewed (summary accepted,
  the ~10 duplicate work-exp suggestions + a bogus "MCP" cert dismissed).
  Open (Mike's judgement, not mechanical): reconcile the EMR-Bear entry vs
  canonical (it's on Indeed, not in the resume); contact location shows
  Crystal Lake IL vs resume's Chicago IL. Do NOT click Indeed's "Review
  suggestions" / "Sync to profile" — it re-adds duplicate work experience.

  Blocked on Mike: nothing outstanding. (GHA billing is moot now — CI removed.)
  No deploy mechanism exists (kamal unconfigured); deploy is out of scope.

  Deferred (YAGNI): first concrete Datalake::Extractor — waits for a consumer.

  DO NOT touch other repos from a wwworkremote/core session (esp. never commit
  content in the public just3ws.github.io). See memory feedback_stay_in_this_repo.

  Deep handoff: ~/.config/adots/handoffs/2026-08-30-wwworkremote-guided-session.md
  (local-only, never commit) — NOT yet updated for session 2; this block is
  the current truth.
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
