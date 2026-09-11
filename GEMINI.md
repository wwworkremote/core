
<!-- ═══════════════════════════════════════════════════════════════════════
     COLD-START RESUME STATE lives in the CURRENT FOCUS block at the top of
     >>> AGENTS.md <<<  — canonical for every agent tool. Read it first.
     Closing a session = rewrite that block in AGENTS.md, then commit.
     ═══════════════════════════════════════════════════════════════════════ -->

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

## Agent Insight Sharing

To ensure insights are shared and "never forgotten" across the system:

1.  **Project-Level (Local):** Contribute to the `SystemInsight` model for technical observations (Brakeman, RuboCop, etc.). These are used by `Quality::ContextBuilder` to provide architectural context.
2.  **Team-Level (Repository):** Record team-shared conventions, architecture rules, or repo-wide workflows in this `GEMINI.md` file.
3.  **Cross-Project (Global):** Record personal preferences, patterns, or insights that apply to *all* projects in the **Global Personal Memory** file (`~/.gemini/gemini.md`).
4.  **Private/Local (Machine):** Record machine-specific notes or private workflows in the **Private Project Memory** (`MEMORY.md` in the project's private memory folder).

## 🛡️ Engineering Mandates

### 1. Database Safety & Environmental Context
**CRITICAL**: The development database contains high-fidelity data and MUST NEVER be reset or modified by test suites.

- **Mandatory Prefix**: ALL shell commands that interact with the Rails stack MUST use an explicit `RAILS_ENV` prefix (e.g., `RAILS_ENV=test bundle exec rspec`).
- **Standard Wrappers**: ALWAYS use `bundle exec` or `bin/` wrappers.
- **Safety Guards**: Respect the guards in `spec/rails_helper.rb`. If you hit a "FATAL ERROR," stop and re-evaluate your environmental context.
- **Account Separation (The zdots Rule)**: Prevent data drift by separating database accounts. Use `_ro` accounts for replicas (SELECT only), `_w` for ingestion syncs (INSERT/UPDATE only), and `_rw` for user-managed UI/Migrations.
- **Asymmetric Sync Rule**: To prevent "record resurrection" during external API syncs, always use Soft Deletes (e.g., `discarded_at`) for user-managed data. Ingestors should never hard-delete or overwrite fields marked as user-modified.
