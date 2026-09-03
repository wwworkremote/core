<!-- ═══════════════════════════════════════════════════════════════════════
     CURRENT FOCUS  —  last updated 2026-09-03 (session 5 close)
     Cold-start resume state, canonical for every agent tool (Claude, Codex,
     Gemini, Antigravity). Whoever closes a session rewrites this whole block
     in place — step one, before the wrap-up. `git log` + Backlog are truth
     for exact SHAs / task status; if this block contradicts them, trust them
     and fix the block. Full procedure: docs/agents/session-handoff.md
     ═══════════════════════════════════════════════════════════════════════

  In flight: TWO stacked PRs open, neither merged — main still @ 6ca8bd72
  for feature code (main HEAD is only doc/focus commits).
    PR #23 https://github.com/wwworkremote/core/pull/23 — branch
      feat/homepage-pipeline-blocks. Homepage leads with Interviews /
      Active Leads / Awaiting Response blocks ("What this app does" cards
      deleted); InterviewSession → ordered multi-round pipeline
      (position/outcome/interviewers, InterviewProcess templates,
      seed_default, in_flight_for). TASK-147.1 steps 1-3; ACs 6+7 open.
    PR #24 https://github.com/wwworkremote/core/pull/24 — branch
      feat/inline-edit-job-posting, STACKED on #23 (base is #23's branch,
      merge #23 first). TASK-148 slice 1: JobPosting core fields editable
      inline on the show page (?section=core turbo frame), JobPosting::
      InlineEditing concern, multi-country data["countries"] + geo_allowed
      honoring it. AC#4 done. Slices 2-4 (UserJobPosting fields, interview-
      round UI, prep/Q&A) not started — see TASK-148 Implementation Notes.
  Session 5 also ran /pipeline-health + local-LLM health — all green
  (verified 2026-09-03), no action.

  Job search: Basis recruiter reached out 2026-09-03 (warm intro — the
  recruiter's note said the internal contact "bragged about" Mike). Call
  was ~10:00 CT. Debrief NOT logged (InterviewSession round 1 has no
  feedback/vibe/questions). Vanguard warm-lead still open.

  Live tasks (Backlog MCP):
    TASK-140  (Med, sharpened session 4) JobBoards::Syncer starves on an
              unordered LIMIT. fetch_pending_docs does
              .where(aasm_state: ["pending", nil]).limit(10) with no ORDER
              BY → re-selects the same ~10 un-convertible oldest rows every
              run. ~36 conversions/day vs ~157/day intake; 6,831 nil-state
              JobBoards::Document rows backlogged since 2026-07-30. Do NOT
              one-line it (order ASC alone blocks FIFO when poison > limit;
              raising the limit floods JobBoards::AnalysisJob's per-posting
              LLM call). Needs a terminal `failed` state / cursor + a
              characterization spec + a one-time bulk drain. 5-step plan in
              the task's Implementation Notes.
    TASK-147  (Med, spike, NEW session 4) design the end-to-end
              career-development lap — ADR + sequenced plan, no impl, for
              making lead → application → interview-prep → interview one
              repeatable, evolvable harness process instead of three layers.
    TASK-147.1 (feature, In Progress, NEW session 5) multi-round interview
              tracking. Steps 1-3 done in PR #23 (InterviewSession =
              round, InterviewTask = action item, InterviewProcess
              TEMPLATES + seed_default + in_flight_for; homepage "Round N
              of M" block). OPEN: AC#6 final-round outcome → UserJobPosting
              wiring; AC#7 posting-page UI to seed a process / set round
              dates+outcomes (console-only right now). Full state in the
              task's Implementation Notes.
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
      UJP #268 = INTERVIEW (advanced from applied session 5 when the
      InterviewSession process was seeded). PipelineStep history +
      GuidedSession #18 completed. Interview process seeded (:compressed,
      6 rounds) — round 1 (recruiter screen) scheduled 2026-09-03 15:00
      UTC, rounds 2-6 unscheduled. THIS IS DEV-DB SEED DATA, not in PR #23.
      Recruiter engaged via warm intro. Basis is formerly Centro (rebrand
      2022), US HQ Chicago + Toronto — corrected in dev DB session 5
      (JP #7068 location "Chicago, IL · Toronto, ON", country_code US,
      data.countries [US,CA]; Centro note on UJP #268 notes). Was
      auto-ignored on promote (bad remote flag + blank company) — restored.
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

  Done 2026-09-03 session 5 (2 stacked PRs OPEN, NOT merged — main still
  @ 6ca8bd72 for feature code):
    - PR #23: homepage redesign (Interviews / Active Leads / Awaiting
      Response pipeline blocks; marketing cards deleted). TASK-147.1
      steps 1-3: InterviewSession position/outcome/interviewers cols,
      relaxed scheduled_at validation, app/models/interview_process.rb
      (3 frozen TEMPLATES + seed_default + in_flight_for), homepage
      "Round N of M" block, show page renders the sequence. Fixed a
      regression: show page crashed on unscheduled rounds (f730cfdb).
    - PR #24 (stacked on #23): TASK-148 slice 1 — JobPosting core fields
      editable inline on the show page, JobPosting::InlineEditing concern,
      multi-country data["countries"] + geo_allowed honoring it.
    - CONTEXT.md +4 domain entries (interview round/task/template, +
      Job Posting = canonical edit surface).
    - Basis interview process seeded in dev DB (:compressed); JP #7068
      location/country data corrected — see above.
    - Slack message to the Basis warm-intro contact drafted (not sent).
  Done 2026-09-02..09-03 session 4 (merged + pushed, main @ 6ca8bd72):
    - TASK-147 filed (design the end-to-end career-development lap, spike).
    - TASK-140 sharpened + bumped Low→Medium — Syncer starvation root-caused
      via /pipeline-health; 5-step fix plan added to the task, not built.
    - /fewer-permission-prompts: 17 read-only tool patterns allowlisted in
      .claude/settings.json.
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

  Blocked on Mike: (1) review + merge PR #23, then PR #24 (stacked);
  (2) pick what to do with the Vanguard lead (4 options above).
  Everything else is unblocked. GHA billing is moot (CI removed). No deploy
  mechanism exists (kamal unconfigured); deploy is out of scope.

  Next build (session 6): TASK-148 remaining slices — UserJobPosting fields
  (notes/priority/applied_at), interview-round editing UI (absorbs
  TASK-147.1 AC#7), body/ai_category, prep-pack/Q&A. TASK-147.1 AC#6
  (final-round outcome → UserJobPosting) is separate + smaller; alongside.

  Deferred (YAGNI): first concrete Datalake::Extractor — waits for a consumer.

  DO NOT touch other repos from a wwworkremote/core session (esp. never commit
  content in the public just3ws.github.io). See memory feedback_stay_in_this_repo.

  Deep handoff: ~/.config/adots/handoffs/2026-09-03-wwworkremote-session5.md
  (local-only, never commit). Earlier: 2026-09-02-wwworkremote-session4.md.
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
