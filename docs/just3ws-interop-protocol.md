# Candidate History & Resume Interop Protocol (`just3ws` ↔ `wwworkremote` ↔ `zdots-ctx`)

This document guides AI agents, scripts, and background jobs running in **`wwworkremote`** on how to query candidate history, resume evidence, and discuss job leads via **`zdots-ctx`** message bus.

---

## 1. Cross-Agent Discussion Channel (`zdots-ctx bus-*`)

AI agents working in `wwworkremote` should post lead evaluations, job match updates, and inter-tool questions to the dedicated `job-leads` channel; use `general` for anything cross-cutting (platform ops, questions for the zdots-kernel session, or to reach Mike directly — Mike, as the platform operator, can read every channel, not just `general`).

* **Channels**: `job-leads` (this two-repo thread), `general` (platform-wide)
* **Commands**:
  ```bash
  # 1. Register agent identity (idempotent; re-run to rotate your own token)
  /Users/mike/.config/zsh/bin/zdots-ctx bus-register agent-wwworkremote --kind agent

  # 2. Post lead evaluation update
  /Users/mike/.config/zsh/bin/zdots-ctx bus-post job-leads "Ingested Lead #126 (Follett). Evaluated as Track Mismatch." --as agent-wwworkremote

  # 3. Read unread messages from other agents
  /Users/mike/.config/zsh/bin/zdots-ctx bus-read job-leads --unread --as agent-wwworkremote
  ```
  Posting requires the token `bus-register` issues (Z-310, closed 2026-08-23) — see
  [`docs/agents/peer-contract-just3ws.md`](agents/peer-contract-just3ws.md) for the full
  identity/trust model and why pre-2026-08-23 `job-leads` history isn't attributable.

---

## 2. Candidate Context Endpoints (`just3ws.localhost`)

`just3ws.localhost` exposes machine-readable APIs derived from canonical data (`_data/resume/`):

* **Structured Resume API (JSON)**: `GET https://just3ws.localhost/resume.json` (http 301s to https; Faraday does not follow redirects)
  - Full candidate `profile`, `summary`, `positions` array, `skills` breakdown, `leadership` records, and `timeline`.

* **Markdown Resume Export**: `GET http://just3ws.localhost/exports/resume.md`
  - High-density Markdown resume for LLM prompt context injection.

* **Case Studies & Cartography**: `GET http://just3ws.localhost/exports/portfolio.md`
  - 4D System Cartography case studies (OneMain Financial, EMR-Bear).

---

## 3. Job-fit scoring lives in `wwworkremote`, not `just3ws`

`bin/evaluate_job_lead.rb` should not re-score fit against `resume.json` — `wwworkremote` already
owns that via `LLM::ProfileMatcher`/`LLM::ArtifactGenerator` (the same code the web UI's "analyze
match" button calls), keyed off the one local `User`'s `career_profile`, not the just3ws resume
export. Two independent scorers would drift. Call the existing one instead:

```bash
cd ~/github.com/wwworkremote/core
bin/wwwr match <job_posting_id> --source=just3ws-cli           # read-only: prints existing analysis
bin/wwwr match <job_posting_id> --source=just3ws-cli --escalate  # runs a fresh LLM scan, persists it
```

`--source` is required on every call — not a credential (everything here is local, single-user),
just an attribution tag logged server-side so it's clear which tool asked. Reads are always safe;
`--escalate` is the one write path (costs LLM tokens, overwrites the stored analysis) and is opt-in
per call. `admin/leads/:id` is a browser-session-authenticated admin view, not an API — don't curl
it from `just3ws`. Full contract: `docs/agents/interop.md` in `wwworkremote/core`.

---

## 4. Calibration Guidelines for AI Workflows

When matching candidate data against job postings:
- **Zero Fluff**: Exclude unevidenced hype ("visionary," "transformational").
- **Fact-Dense Alignment**: Pair job requirements directly with verified metrics and achievements (-60% MTTR, 36+ OpenTelemetry services, 130+ clinics).
- **Track Matching**: Distinguish Principal IC architecture roles from Executive People Management roles.
