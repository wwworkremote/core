<!-- ═══════════════════════════════════════════════════════════════════════
     CURRENT FOCUS  —  last updated 2026-09-02 (session 4)
     Cold-start resume state, canonical for every agent tool (Claude, Codex,
     Gemini, Antigravity). Whoever closes a session rewrites this whole block
     in place — step one, before the wrap-up. `git log` + Backlog are truth
     for exact SHAs / task status; if this block contradicts them, trust them
     and fix the block. Full procedure: docs/agents/session-handoff.md
     ═══════════════════════════════════════════════════════════════════════

  In flight: nothing half-built. Session 4 built the Interview Prep Pack
  feature end-to-end (TASK-144 + .1/.2/.3/.4, all Done) on branch
  `feat/interview-prep-pack` — merge to main pending Mike's push go. Job
  search is still the active thread: Basis interview was 2026-09-03 10:00 CT
  (warm intro via a UGtastic contact); Vanguard warm-lead still open.

  Live tasks (Backlog MCP):
    TASK-145  (High, NEW) LLM::Orchestrator always fails on the Gemini provider
              ("Role 'system' is not supported"). defaults.answer_generation
              has pointed at gemini-3.7-flash since 2026-08-24 → every AI-path
              screening answer has been silently failing. Also blocks a
              stronger model on the interview-prep path. Repro + root cause in
              the task (Streamer replays roles verbatim, bypassing RubyLLM's
              system→system_instruction mapping).
    TASK-146  DONE session 4 — man/wwwr.1 + completions/wwwr.{bash,zsh} added
              for the whole bin/wwwr CLI, not just interview-prep.
    TASK-112  guided recorder — HITL ACs (#3 annotate, #4 approve, #5 replay).
              First real run done vs Basis/Lever this session, but Lever isn't
              first-class (TASK-143) so it was thin. Still wants a clean run
              on a supported ATS (Greenhouse) with a full annotate/approve/
              replay pass. In Progress.
    TASK-143  (Med, NEW) guided harness has no first-class Lever support — the
              submit-block is hardcoded to the sandbox's `#application-form`,
              and Lever drops the `?guided_session_token` query string on the
              `/apply` navigation, so on Lever the harness *records* the lap
              (DOM/HAR/page-arrivals) but does NOT gate the submit. Ingestion
              side already works. Full scope in the task.
    TASK-142  (Low, NEW) `bin/verify_claude_assets` / the ClaudeAssets
              pre-commit hook is pre-broken on main — it follows the ~38
              `.agents/skills` symlinks under `.claude/skills/` which lack
              `metadata.version`. Any commit touching `.claude/` needs
              `SKIP=ClaudeAssets` until fixed.
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

  Operational state (verified 2026-08-31 session 3): dev server up (200, fast),
  puma cluster mode + watchdog recurring job self-healing wedges in ~2-3 min.
  Ingestion live, 13 recurring jobs, AI matching hourly, dashboard renders.

  Job search — applications tracked:
    Basis, "Sr Software Engineer - Basis Platform / DSP" (Lever) — JP #7068,
      UJP #268 = applied, PipelineStep #999 (resume archetype + both Q&A
      answers + the Lever "error verifying" retry noted), GuidedSession #18
      completed. Direct contact also engaged. US+remote confirmed in the JD;
      the "Toronto, ON" line was just where the req is filed. Was auto-ignored
      on promote (bad remote flag + blank company) — restored + fixed.
    Vanguard — warm lead via a former colleague (ex-OMF, ran the OTel WG after Mike,
      actively pulling to get him in). Company #1112. Two reqs already
      ingested 2026-08-25: JP #6740 "AI Enablement, Specialist" (Charlotte NC,
      UJP #250 favorited, NOT match-scored — this is likely the referrer's target;
      maps to Mike's enablement track); JP #6747 "Lead Backend Engineer -
      Mobile APIs" (auto-ignored). Both flagged remote=false / Charlotte —
      could be a bad extract like Basis, or genuine RTO (Vanguard is
      in-office-heavy) → a relocation/hybrid question for Mike + [redacted-name], not a
      filter question. Session ended with Mike still deciding; open offers to
      him: match-score #6740, restore #6747 + recheck remote flags, log the
      the referrer referral as a PipelineStep on #250, maybe wire the
      vanguardjobs.com board.

  NEW standing criterion (memory feedback_culture_fit_over_comp, 2026-08-31):
  weight team/culture/belonging fit ABOVE marginal comp — a warmer lower-comp
  role should rank above a colder higher one. Mike + [redacted-name] explicitly prefer
  "appreciated for less" over "not, for a bit more". The $200k base floor
  still holds; this is about weighing everything above it. Not yet reflected
  in LLM::ProfileMatcher — that's a build task if Mike wants it.

  Done 2026-09-02 session 4 (branch feat/interview-prep-pack, ~19 commits,
  merge to main pending Mike's push go):
    - Interview Prep Pack: LLM-generated briefing per posting (role setup,
      domain primer w/ acronym→authority binding, story arc, hooks, referral
      play, likely questions, questions to ask, checklist). Button on the job
      posting page + `bin/wwwr interview-prep <id>`. TASK-144 + .1 (domain
      primer) + .2 (skill + interview-prep-auditor agent) + .4 (docs/diagrams).
    - Read-aloud version (TASK-144.3): `interview_prep_pack_spoken`, a
      SpokenRewriter pass → TTS-clean prose + a `format: read-aloud` YAML
      frontmatter block. `--export[=<role>]` writes pack.md + pack.spoken.md
      to ~/ai/outbox/wwwr/interview-prep/<role>/. Convention doc'd:
      docs/interview-prep/ (standard, transform prompt, integration guide);
      diagrams in docs/architecture/interview-prep-tooling.md.
    - `format: read-aloud` frontmatter is now a repo-wide convention (memory
      feedback_read_aloud_document_convention).
    - TASK-145 filed (Gemini orchestrator bug, pre-existing, High).
    - Basis interview 2026-09-03 prepped (hand-written pack:
      docs/interview-prep/basis-dsp/reference.md is the better one for the
      actual interview; the generated one is the working pipeline).
  Done 2026-08-31 session 3 (pushed, main @ c220a057 + this block commit):
    - indeed-profile-sync skill + indeed-profile-auditor agent (cfaf1f45)
    - "Start supervised application" button on the admin Lead page (fed55f9e,
      c220a057) — second entry to guided_sessions#create_from_posting
    - first real guided-session dogfood (Basis/Lever) — surfaced TASK-143
    - TASK-142 / TASK-143 filed
  Done 2026-08-31 session 2 (main @ 36365d81): guided-session top-nav + inline
  URL form; build stamp in footer; docs/applying-with-the-harness.md; TASK-141
  filed+mitigated (cluster mode + WebHealthWatchdogJob); CI removed entirely
  (ci.yml + bin/ci deleted).
  Done 2026-08-31 session 1: TASK-138 / TASK-126 / TASK-84 closed; TASK-140.

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
  Workflow codified: `indeed-profile-sync` skill + `indeed-profile-auditor`
  subagent (Claude Code only — needs Claude-in-Chrome). Re-run when the
  resume changes or Mike takes/leaves a role.

  Blocked on Mike: pick what to do with the Vanguard lead (4 options above).
  Everything else is unblocked. GHA billing is moot (CI removed). No deploy
  mechanism exists (kamal unconfigured); deploy is out of scope.

  Deferred (YAGNI): first concrete Datalake::Extractor — waits for a consumer.

  DO NOT touch other repos from a wwworkremote/core session (esp. never commit
  content in the public just3ws.github.io). See memory feedback_stay_in_this_repo.

  Deep handoff: ~/.config/adots/handoffs/2026-09-02-wwworkremote-session4.md
  (local-only, never commit). Earlier: 2026-08-31-wwworkremote-session3.md.
  This block is the current truth if they disagree.
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
