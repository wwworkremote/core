## Agent skills

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
