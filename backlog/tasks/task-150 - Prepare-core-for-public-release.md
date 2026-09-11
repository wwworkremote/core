---
id: TASK-150
title: Prepare core for public release
status: In Progress
assignee: []
created_date: '2026-09-04 13:12'
updated_date: '2026-09-04 13:16'
labels: []
dependencies: []
priority: high
type: chore
ordinal: 100
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TOP PRIORITY. Full prep to make wwworkremote/core public and "proud to publish" — everything EXCEPT the visibility flip, which Mike holds.

Plan (approved): /Users/mike/.claude/plans/silly-baking-hennessy.md
Deep handoff: ~/.config/adots/handoffs/2026-09-04-wwworkremote-session6.md

DECISIONS — all locked by Mike 2026-09-04:
- D1: flip core IN PLACE (not a new repo) after a history reset
- D2: SCRUB EVERYTHING IN PLACE — backlog/, AGENTS.md, CLAUDE.md, docs/agents/* all STAY in the public repo, scrubbed. (This overrides the plan's written recommendation to remove them. Mike chose one-repo + permanent scrub discipline.)
- D3: Apache-2.0 + NOTICE
- D4: orphan-squash to ONE clean root commit (kills all pre-scrub history + the .env history problem in one move)
- D5: README = systems story (domain-driven Rails platform; job-search is the substrate, not the pitch)
- D6: remove data/backfills/*.json (12MB third-party HN data)

TWO HARD BLOCKERS:
1. .env is git-tracked since 2021 (keys: ADMIN_PASSWORD, ANTHROPIC_API_KEY, GEMINI_API_KEY, OPENAI_API_KEY, ADZUNA_APPLICATION_KEY, DATABASE_URL, OTEL/OLLAMA bases). Mike must eyeball .env AND confirm no historical version held a real value. .env.local (untracked) likely holds the real secrets. → Phase 0, Mike owns it. If any value was ever real: rotate that credential regardless.
2. backlog/ names a LIVE interview: task-143/144/144.1-.3/148/149 name "[redacted]" (Sr SWE, [redacted] Platform/DSP), the Lever URL jobs.lever.co/[redacted]/[redacted], "[redacted]" (the internal referrer), the 2026-09-03 interview, JP#7068 / Lead#191 / UJP#268, and "[redacted], [redacted], etc."

Nothing executed yet. Branch prep/public-release was created then deleted (empty) — next session recreates it.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Phase 1: .env untracked + .env.example added; live-interview/real-name strings scrubbed from tree; internal coordination content removed from public branch; bin/tmi-scan added and green; Apache-2.0 LICENSE + NOTICE; rspec + rubocop green
- [ ] #2 Phase 2: SVG logo + brand sheet + rewritten README + draft org profile README, reviewed via Artifact
- [ ] #3 Phase 3: history-reset runbook written (NOT executed)
- [ ] #4 Phase 4: flip runbook written (NOT executed)
- [ ] #5 No visibility change, no force-push, no org edits, no just3ws.github.io edits
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Work on branch `prep/public-release` (recreate: `git checkout -b prep/public-release` off main).

## Phase 0 — MIKE (blocks Phase 3 only, not 1/2)
Mike verifies `.env` values + all historical versions are placeholders. Rotate anything real.

## Phase 1 — Scrub forward (branch, NO history rewrite, NO flip)
1a. Secrets: `git rm --cached .env`; write `.env.example` (key names known, placeholder values); confirm .gitignore covers it (line 28 does).
1b. Build the TMI guard FIRST, use it to drive the rest:
    - `config/tmi_denylist.yml.example` (committed) + `config/tmi_denylist.yml` (gitignored): real names ([redacted], referrer real name if known, "[redacted]"), "[redacted]", comp figures ([redacted] floor, $[redacted]), home-town/location hints, "[redacted]", "[redacted]".
    - `bin/tmi-scan` (~25 lines): `git grep -iE` denylist across tracked files + `git log -p -S<term>` spot-check; exit non-zero on hit.
    - Wire as overcommit pre-commit WARNING (not hard-fail; false-positive prone).
1c. Scrub tracked-file hits (run bin/tmi-scan to find them all; known ones):
    - backlog/tasks/task-143, 144, 144.1, 144.2, 144.3, 148, 149 → "[redacted]"/"[redacted] Platform / DSP"/Lever URL/"[redacted]"/"[redacted], [redacted]"/UJP#268 → generic ("a mid-size adtech company", "the DSP role", "the referrer"). JP#7068/Lead#191 are local dev IDs, lower risk but tied to the story — genericize too.
    - spec/services/llm/interview_prep_generator/prompt_builder_spec.rb:7,17 → company_name: "[redacted]" / "Build the DSP." → "Acme" / generic body (update BOTH the let() and the expect()).
    - app/services/llm/interview_prep_generator/spoken_rewriter.rb ~L22-24,L40 → prompt EXAMPLE strings "DSP"/"[redacted]": "BAY sis" / "$[redacted]" → "Acme" / fake range. Illustrative only.
    - docs/interview-prep/tts-readable-documentation.md:114 + tts-transform-prompt.md:164 → "Siobhan" respelling example → different name.
1d. Coordination docs — SCRUB IN PLACE (D2), do NOT delete:
    - AGENTS.md: the CURRENT FOCUS block is the live risk. Rewrite it to a slim public cold-start: keep the resume/close protocol + live task IDs + "blocked on Mike" list; DROP the EXPOSURE PASS narrative (lines ~132-156 name "names/address/comp/grievance strings", "referrer PII", "[redacted]-dsp/ path" — a treasure map), DROP "one interview in progress / referral lead being evaluated", DROP the dangling-SHA warning once Phase 3 is done. Session-close protocol stays (it's fine to be public).
    - CLAUDE.md: strip "private job-market-intelligence engine", the just3ws-peer + `zdots-ctx bus-*` identity/token section, the "fabricated two-party handshake" history paragraph. Keep skills list + Backlog workflow + bin-scripts pointers.
    - GEMINI.md: tiny pointer file — light touch.
    - docs/agents/peer-contract-just3ws.md: scrub — it's interop authority boundaries (mostly fine) but frames "that repo public / this one private" and the bus token model.
    - docs/agents/just3ws-pending-changes.md: says "repo stays private as a whole" — rewrite or delete (queue is closed anyway).
    - docs/agents/session-handoff.md: fine to be public, scan for names.
    - .claude/agents/* job-search personas (career-coach, recruiter, hiring-manager, hr, customer, indeed-profile-auditor, interview-prep-auditor, industry-intelligence): NOT PII. Sub-decision for Mike — lean keep (shows the AI-assisted workflow, portfolio-interesting). Flag, don't delete unilaterally.
1e. LICENSE → Apache-2.0 text; add NOTICE ("WWWorkRemote — © 2021–2026 Mike Hall"). CONTRIBUTING.md → trim LinkedIn-voice, keep DB-safety + adapter sections.
1f. `git rm data/backfills/*.json`; gitignore `data/backfills/`.
1g. Gate: `bundle exec rspec` green · `bin/rubocop` clean · `bin/tmi-scan` exit 0 · pipeline-health script green. Open PR, review full diff.

## Phase 2 — Branding (files only, nothing pushed public)
- SVG logo (2-3 concepts, wordmark + mark) in app/assets/images/brand/; regenerate public/icon.svg + favicon.ico + public/icon.png.
- docs/brand/README.md: palette (reuse app CSS color tokens), type, logo usage.
- README.md full rewrite (D5 systems-story). Reuse an existing mermaid diagram from docs/architecture/ (component-overview.md / panoramic-view.md). FIX stale quick-start (README says localhost:31000 + bin/dev — verify against reality).
- Draft wwworkremote/.github/profile/README.md update featuring core (as a FILE; Mike pushes it — separate repo).
- Publish an Artifact preview of README + brand sheet for Mike.

## Phase 3 — History reset RUNBOOK (WRITE IT, DO NOT RUN IT)
Needs Phase 0 done + Phase 1 merged + PRs #23/#24 merged-or-closed first.
1. Bundle backup: `git bundle create ~/.../wwwr-pre-public-$(date +%s).bundle --all`
2. `git checkout --orphan public-main` → single "Initial public release" commit from cleaned tree → becomes main
3. `git push origin --delete bakup` (un-rewritten ancient orphan branch)
4. `git reflog expire --expire=now --all && git gc --prune=now --aggressive`
5. `git push --force origin main` + delete stale remote feature branches
6. Verify: `git log --all -p | grep -iE '<denylist>'` empty; `git rev-list --all --objects | grep -E 'data/backups|data/backfills|corpus\.json|\.env$'` empty

## Phase 4 — The flip RUNBOOK (WRITE IT, DO NOT RUN IT — Mike triggers)
- `gh repo edit wwworkremote/core --visibility public --accept-visibility-change-consequences`
- set description/homepage(just3ws.com)/topics
- pin core on org; push .github profile README
- `gh repo archive` stale private org repos: dashboard (2023), ops/binder/actions (2021)
- final `bin/tmi-scan` on the public tree

## GOTCHAS
- Commits touching .claude/ need `SKIP=ClaudeAssets` (TASK-142, hook pre-broken).
- Pre-commit runs full RSpec (~2min) — use `timeout: 550000` on commit Bash calls.
- RuboCop hook is `-a` (safe autocorrect only); strict 5-line MethodLength.
- NEVER `git add` the handoff file (~/.config/adots/handoffs/*).
- config/tmi_denylist.yml, config/commute_zone.yml, config/job_search_criteria.yml are all gitignored — never commit.
<!-- SECTION:PLAN:END -->
