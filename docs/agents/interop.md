# Local interop: other on-box tools/agents talking to wwworkremote

This app runs entirely locally, single-user (`User.sole`). Other local tools/agents (e.g. the
`just3ws` CLI, which holds the canonical resume/profile narrative) should not re-implement job-fit
scoring against a duplicate copy of the resume — this app already owns that via
`LLM::ProfileMatcher` / `LLM::ArtifactGenerator`, the same code the web UI's "analyze match" /
"generate artifacts" buttons call. Query it here instead of scoring independently.

## Entry point

`bin/wwwr match <job_posting_id> --source=<name> [--escalate] [--artifact]`

- **`--source=<name>`** — required on every call. Not a credential: this is a local single-user
  app, there's nothing to authenticate. It's an attribution tag, logged as
  `[interop] source=<name> action=<read|escalate> job_posting=<id>` so a live `tail -f log/development.log`
  (or a later audit) shows which tool asked for what.
- **Read (default, no flag)** — prints the existing `match_score` / `match_tags` / `match_analysis`
  off the `UserJobPosting` if one has already been run. No LLM call, no write, unrestricted.
- **`--escalate`** — runs `LLM::ProfileMatcher.call` (or `LLM::ArtifactGenerator.call` with
  `--artifact`) for real: costs LLM tokens, persists the result. This is the one write path, and
  it's opt-in per call on purpose — reads are always safe to script/poll, writes are not.

Logic lives in `Wwwr::Interop` (`lib/wwwr/interop.rb`), dispatched from `Wwwr::CLI#run_match`
(`lib/wwwr/cli.rb`) so it's covered by `spec/lib/wwwr/cli_spec.rb` without shelling out.

## What NOT to build

- Don't hit `admin/leads/:id` from another tool for this — it's a browser-session-authenticated
  admin view, not an API, and isn't meant to be curled from a script.
- Don't call `LLM::ProfileMatcher`/`ArtifactGenerator` directly from another repo's `rails runner`
  invocation — go through `bin/wwwr match` so the `--source`/`--escalate` contract (and its log
  trail) stays in one place.
