<!-- ═══════════════════════════════════════════════════════════════════════
     CURRENT FOCUS  —  last updated 2026-09-06 (session 7 close)
     Cold-start resume state, canonical for every agent tool (Claude, Codex,
     Gemini, Antigravity). Whoever closes a session rewrites this whole block
     in place — step one, before the wrap-up. `git log` + Backlog are truth
     for exact SHAs / task status; if this block contradicts them, trust them
     and fix the block. Full procedure: docs/agents/session-handoff.md
     ═══════════════════════════════════════════════════════════════════════

  ★ TOP PRIORITY — TASK-150: prepare this repo to go PUBLIC.
     Mike wants wwworkremote/core public and "proud to publish" (logo,
     branding, real README, org featuring it). He is HOLDING the visibility
     flip — the task does everything up to but not including it.
     Full plan:   /Users/mike/.claude/plans/silly-baking-hennessy.md
     Deep handoff: ~/.config/adots/handoffs/2026-09-06-wwworkremote-session7.md
     Task:        TASK-150 (High, In Progress) — carries the sequenced
                  Phase 1–4 plan + all the specific scrub targets + gotchas.
     Decisions LOCKED by Mike 2026-09-04: D1 flip in place · D2 scrub
     everything in place (backlog/, AGENTS.md, CLAUDE.md all stay public,
     scrubbed — one repo, permanent scrub discipline) · D3 Apache-2.0 ·
     D4 orphan-squash to one clean root commit · D5 README = systems story ·
     D6 drop data/backfills/*.json.
     NOTHING EXECUTED YET. Start at TASK-150 Phase 1 on a fresh branch
     `prep/public-release`. Two hard blockers: (1) `.env` is git-tracked
     since 2021 — MIKE must verify its values + history are placeholder-only
     (Phase 0); (2) backlog tasks 143/144/144.1-.3/148/149 name a live
     interview (company "Basis", referrer "Beep", the Lever URL, dates).

  ⚠ GIT HISTORY WAS REWRITTEN 2026-09-03 (git filter-repo ×2, exposure pass).
     Every pre-2026-09-03 commit SHA is DANGLING — don't `git show` it.
     `git log` + Backlog are the only truth. origin/bakup was NOT rewritten
     (ancient orphan branch — Phase 3 deletes it). Pre-rewrite bundle:
     scratchpad/wwwr-pre-*.bundle (local). TASK-150 Phase 3/4 does the
     final orphan-squash + flip.

  In flight: TWO stacked PRs open, neither merged. Feature code is only on
  the PR branches; main carries exposure-pass + doc commits + TASK-150.
    PR #23 https://github.com/wwworkremote/core/pull/23 — branch
      feat/homepage-pipeline-blocks. Homepage leads with Interviews /
      Active Leads / Awaiting Response blocks; InterviewSession → ordered
      multi-round pipeline (position/outcome/interviewers, InterviewProcess
      templates). TASK-147.1 steps 1-3; ACs 6+7 open.
    PR #24 https://github.com/wwworkremote/core/pull/24 — branch
      feat/inline-edit-job-posting, STACKED on #23 (merge #23 first).
      TASK-148 slice 1: JobPosting core fields editable inline on the show
      page. Slices 2-4 not started — see TASK-148 Implementation Notes.
  These must be merged-or-closed BEFORE TASK-150 Phase 3 (history reset).

  Job search: active threads and application state live in the app
  (`/user_job_postings`, `/home`) and the local deep handoff — not here.
  Basis: Round 1 advanced; Round 2 scheduled for Tuesday, Sep 8, 2026 at 10:00 AM CDT
  (1-hour React-focused technical interview, UJP #268 / sessions 2 & 3).

  Live tasks (Backlog MCP):
    TASK-150  ★ (High, In Progress) prepare the repo for public release —
              see the ★ block above. This is the priority.
    TASK-140  (Med) JobBoards::Syncer starves on an unordered LIMIT.
              fetch_pending_docs .where(aasm_state:[…]).limit(10) has no
              ORDER BY → re-selects the same ~10 un-convertible oldest rows.
              ~6,831 nil-state rows backlogged since 2026-07-30. Needs a
              terminal `failed` state / cursor + characterization spec +
              one-time bulk drain. 5-step plan in the task.
    TASK-147  (Med, spike) design the end-to-end career-development lap —
              ADR + sequenced plan, no impl (lead → application →
              interview-prep → interview as one repeatable harness).
    TASK-147.1 (feature, In Progress) multi-round interview tracking.
              Steps 1-3 in PR #23. OPEN: AC#6 final-round outcome →
              UserJobPosting wiring; AC#7 posting-page UI to seed a
              process / set round dates+outcomes.
    TASK-145  (High) LLM::Orchestrator always fails on the Gemini provider
              ("Role 'system' is not supported"). defaults.answer_generation
              → gemini since 2026-08-24 → every AI-path screening answer
              silently failing. Also blocks a stronger interview-prep model.
              Repro + root cause in the task.
    TASK-143  (Med) guided harness has no first-class Lever support — the
              submit-block is hardcoded to the sandbox's `#application-form`
              and Lever drops `?guided_session_token` on `/apply`, so on
              Lever the harness records but does NOT gate the submit.
    TASK-142  (Low) `bin/verify_claude_assets` / ClaudeAssets pre-commit
              hook is pre-broken on main (follows ~38 `.agents/skills`
              symlinks lacking `metadata.version`). Any commit touching
              `.claude/` needs `SKIP=ClaudeAssets` until fixed.
    TASK-141  (High, In Progress) dev web service com.wwworkremote.web
              wedges silently. MITIGATED: cluster mode + WebHealthWatchdogJob
              every-minute recovery. Root cause still open.
    TASK-139  (Med) execution chrome.debugger dies before the 2nd capture
              (target_closed); needs a hands-on retest without
              Claude-in-Chrome attached.
    TASK-112  guided recorder — HITL ACs (#3 annotate, #4 approve, #5
              replay). Wants a clean run on a supported ATS (Greenhouse).

  Operational state (verified 2026-09-06): dev server up (200, fast); puma
  cluster mode + watchdog self-healing wedges in ~2-3 min. com.wwworkremote.jobs
  (SolidQueue + cron + aggregators) re-enabled and running. Tooling namespace
  renamed to bin/wwwr-* (bin/wwwr-ctl, bin/wwwr-jobs, bin/wwwr-web) with
  backward-compatible symlinks. ArbeitNow paused and excluded from results.

  Standing scoring requirement (memory feedback_culture_fit_over_comp):
  LLM::ProfileMatcher should weight team/culture fit above marginal
  compensation as a first-class factor. Not yet implemented — build task.

  Done 2026-09-06 session 7 (main):
    - RubyGems bumped (Gemfile.lock verified satisfied).
    - Renamed bin/wwworkremote-* -> bin/wwwr-* (wwwr-ctl, wwwr-jobs, wwwr-web)
      and added compatibility symlinks. Updated docs/config references.
    - Disabled ArbeitNow ingestion and results exclusion in dev DB + bin/fetch-jobs.
    - Re-enabled com.wwworkremote.jobs LaunchAgent; verified both web and jobs running.
    - Updated Basis role: Round 1 outcome marked advanced; Round 2 scheduled
      for Tuesday, Sep 8, 2026 at 10:00 AM CDT (Technical, 1-hour React focus).
      UserJobPosting #268 notes updated.
  Done 2026-09-04 session 6 (main, no feature code — planning only):
    - Filed TASK-150 (prep core for public release) + wrote the approved
      plan (silly-baking-hennessy.md) + the deep handoff. Locked 6
      decisions with Mike (D1-D6 above). No repo files changed except this
      block + the task file.
    - Reviewed just3ws.github.io's tmi-auditor skill as the model for a
      repo-content TMI guard (TASK-150 Phase 1b: bin/tmi-scan + denylist).
  Done 2026-09-03 session 5 (2 stacked PRs OPEN, not merged; main @ 6ca8bd72
  for feature code):
    - PR #23 homepage redesign + PR #24 inline-edit slice 1 (see In flight).
    - CONTEXT.md +4 domain entries.
    - EXPOSURE PASS: repo is private but scrubbed personal detail from the
      coordination layer (pseudonymized a referral contact, dropped
      spouse name / comp figures / home-town hints, replaced the job-search
      dossier with app pointers). Geo::CommuteZone + StandingCriteria made
      config-driven (config/*.yml gitignored, .example committed).
      TASK-149 DONE: company-named interview-prep reference → fully
      synthetic. Then TWO git filter-repo passes rewrote all history
      (pre-scrub strings + a path; then data/backups/ — two pg_dumps with
      real table data). Force-pushed main + both PR branches. .git 123MB→31MB.
      Full detail: scratchpad/exposure-review-2026-09-03.md (local).
      Residual (now folded into TASK-150): origin/bakup un-rewritten;
      GitHub ~90d object retention; lib/corpus.json + data/backfills/*.json
      still history bloat.

  Blocked on Mike:
    (1) TASK-150 Phase 0 — verify `.env` values + history are placeholders
        (rotate anything real). This gates Phase 3.
    (2) Review + merge PR #23, then PR #24 (stacked). Gates Phase 3.
    (3) Sub-decision: do the .claude/agents/* job-search personas stay in
        the public repo? (lean keep — portfolio-interesting, not PII).
    (4) Job-search decisions — tracked in the app + the deep handoff.

  Next (session 8): start TASK-150 Phase 1 on branch `prep/public-release`.
  Phase 1b (bin/tmi-scan + denylist) first — use it to drive the scrub.

  Deferred (YAGNI): first concrete Datalake::Extractor — waits for a consumer.

  DO NOT touch other repos from a wwworkremote/core session (esp. never
  commit content in the public just3ws.github.io). See memory
  feedback_stay_in_this_repo.

  Deep handoff: ~/.config/adots/handoffs/2026-09-06-wwworkremote-session7.md
  (local-only, never commit). Earlier: 2026-09-04-wwworkremote-session6.md.
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
- **metaphor-harmony**: Audit and harmonize system metaphors, domain language (`CONTEXT.md`), and conceptual models (`.claude/skills/metaphor-harmony/SKILL.md`).
- **domain-cartographer-agent**: Dedicated agent (`.claude/agents/domain-cartographer-agent.md`) for maintaining conceptual harmony between the Embodied Rider and Forensic Observer, preventing domain drift, and ensuring sharp dogfooding ergonomics.

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
