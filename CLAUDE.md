<!-- ═══════════════════════════════════════════════════════════════════════
     CURRENT FOCUS  —  last updated 2026-08-30
     This block is the cold-start resume state. Whoever closes a session
     rewrites it (the whole block, in place) before wrapping up. `git log`
     + Backlog are the source of truth for exact SHAs / task status; if
     this block contradicts them, trust them and fix the block.
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
  GitHub Actions cut to one job on main (ci.yml).

  Blocked on Mike: GitHub Actions billing (Settings → Billing & plans) —
  nothing runs in CI until cleared. No deploy mechanism exists (kamal
  unconfigured); deploy is out of scope.

  Full detail: ~/.config/adots/handoffs/2026-08-30-wwworkremote-guided-session.md
  (local-only, never commit). How-to-resume: docs/agents/session-handoff.md.
-->

## System identity

This is `wwworkremote/core` — the private job-market-intelligence and application-automation
engine half of Mike's two-repo job-search system. Its peer is `just3ws.github.io` (public
resume/portfolio profile, canonical candidate data). Neither is standalone: they coordinate.

**Cross-repo bus** (`zdots-ctx`, local-only): this repo's identity is `agent-wwworkremote`.
Before posting, confirm it resolves:
```
zdots-ctx bus-whoami --as agent-wwworkremote
```
If unregistered (or `bus-whoami` fails), `zdots-ctx bus-register agent-wwworkremote --kind
agent` — note this **rotates** the token if the name already exists, invalidating whatever
was posting under it before, so don't re-run it speculatively once it's working. Channels:
`job-leads` (the two-repo coordination thread with `agent-just3ws`), `general`
(platform-wide; reaches the zdots-kernel session as `zdots`, formerly `claude-code-main`).
Mike, as platform operator, can read every channel, not just `general`. Read before posting:
`zdots-ctx bus-read <channel> --unread --as agent-wwworkremote`.

Don't treat pre-2026-08-23 `job-leads` history between `agent-wwworkremote` and
`agent-just3ws` as a real prior agreement — before that date the bus resolved identities by
`find_or_create` with no auth, and a single actor fabricated a two-party handshake between
those exact two names (registrations 299ms apart). Posting now requires a token
`bus-register` issues (zdots `f06d9acf`, closed as Z-310 in zdots `c4782e61`); that's why
those two names came back frozen rather than auto-migrated. Known ceiling: the token lives
in the login Keychain, which is per-user not per-process, so any local process running as
Mike can still read it — this makes forgery deliberate, not impossible. Full model: zdots
`docs/message-bus.md#identity-and-trust`; this repo's side of the history: `docs/agents/
peer-contract-just3ws.md`.

**Read-path interop contract**: `docs/agents/interop.md` — other local tools query this repo's
job-fit scoring via `bin/wwwr match`, never by re-implementing it.

## Agent skills

### Resuming a session
The **CURRENT FOCUS** block at the top of this file is the cold-start state — read it first.
`docs/agents/session-handoff.md` has the full resume procedure; the deep handoff is a
local-only file it names. Closing a session = update the CURRENT FOCUS block before wrapping.

### Issue tracker
GitHub Issues via `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels
Standard roles: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs
Single-context layout at the root. See `docs/agents/domain.md`.

### bin/ scripts index
Full list of what every `bin/*` script does and when to use it — check here before writing a new `bin/rails runner` one-liner or a new script for something that might already exist. See `docs/agents/bin-scripts.md`.

### bin/ script conventions
Never let a `bin/*` script or rake task write real ActiveRecord rows under `RAILS_ENV=test` outside RSpec's transactional wrapper — it pollutes the shared test DB for every spec after it. See `docs/agents/bin-script-conventions.md`.

### Backlog hygiene audits
Use the `backlog-audit` skill (or the `backlog-audit-agent` subagent for a context-isolated pass) when asked to check whether the backlog is clean — it root-causes bug tasks against git history before assuming they're still open, not just re-reading descriptions.

### Onboarding a new direct-hiring company board
Use the `direct-hiring-board-verify` skill and `bin/verify_board` to confirm a new ADP/Workday/Greenhouse/Lever tenant slug actually works before adding it to `db/seeds.rb` or a Query's boards list.

### Local interop with other on-box tools/agents
Other local tools (e.g. the just3ws CLI) that need job-fit scoring should call `bin/wwwr match <job_posting_id> --source=<name> [--escalate]` rather than re-implementing scoring against a separate resume copy — reads are unrestricted, `--escalate` gates the one write path (an LLM call). See `docs/agents/interop.md`.

### Chrome extension versioning
Bump `version` in `extension/manifest.json` whenever any file under `extension/` changes (even a small fix), unless doing so would break something. Nothing in the codebase reads or depends on this value — it's for tracking which build is loaded in `chrome://extensions`. Full semver, `major.minor.patch`:
- **patch** — copy/wording fixes, color/theme tweaks, selector adjustments, bug fixes that don't change behavior a user would notice as a new capability.
- **minor** — new capability (a new provider/board, a new panel feature, a new message type between content/background/sidepanel).
- **major** — breaking changes to the extension's own contract (e.g. incompatible message-passing shape between content.js/background.js/sidepanel.js, dropped provider support, storage schema change that isn't backward-read-compatible).

<!-- BACKLOG.MD MCP GUIDELINES START -->

<CRITICAL_INSTRUCTION>

## BACKLOG WORKFLOW INSTRUCTIONS

This project uses Backlog.md MCP for all task and project management activities.

**CRITICAL GUIDANCE**

- If your client supports MCP resources, read `backlog://workflow/overview` to understand when and how to use Backlog for this project.
- If your client only supports tools or the above request fails, call `backlog.get_backlog_instructions()` to load the tool-oriented overview. Use the `instruction` selector when you need `task-creation`, `task-execution`, or `task-finalization`.

- **First time working here?** Read the overview resource IMMEDIATELY to learn the workflow
- **Already familiar?** You should have the overview cached ("## Backlog.md Overview (MCP)")
- **When to read it**: BEFORE creating tasks, or when you're unsure whether to track work

These guides cover:
- Decision framework for when to create tasks
- Search-first workflow to avoid duplicates
- Links to detailed guides for task creation, execution, and finalization
- MCP tools reference

You MUST read the overview resource to understand the complete workflow. The information is NOT summarized here.

</CRITICAL_INSTRUCTION>

<!-- BACKLOG.MD MCP GUIDELINES END -->
