---
name: pipeline-health
description: "Check whether the job-ingestion pipeline (scraping, enrichment, dashboard sync, link monitoring) is actually running and producing data. Use when the user asks 'is the pipeline running', 'are jobs being ingested', 'is anything actually working', 'why is nothing showing up', or wants a health check after a deploy or a long refactor session. Distinguishes real code bugs from worker/infra issues (dead workers, OOM, missing dependencies) so the two don't get conflated."
metadata:
  version: 1.0.0
---

# Pipeline Health Check

Answers "is the ingestion pipeline actually working right now" with live data,
not test-suite status. A green test suite says the code is *correct in
isolation* — it says nothing about whether SolidQueue workers are alive,
whether recurring jobs are actually firing on schedule, or whether a
NameError is silently eating every run of some job class in production/dev.

## Steps

1. **Run the snapshot script** (read-only, makes no writes):

   ```
   bin/rails runner .claude/skills/pipeline-health/scripts/check_pipeline_health.rb
   ```

2. **Read the sections in this order:**
   - **Ingestion volume** — is `job_postings` growing? Compare "last 24h" against
     "last 7d / 7" as a rough daily baseline. Zero or near-zero recent volume
     with a healthy 7-day count means something stopped recently, not that the
     pipeline never worked.
   - **SolidQueue backlog** — a growing `pending jobs` count with low
     `finished last 24h` means jobs are queuing but not draining: no worker is
     consuming them, or the worker is stuck/crash-looping.
   - **Failed jobs by class / error samples** — each sample is pre-tagged:
     - `CODE BUG` (NameError, uninitialized constant, NoMethodError): a real
       defect. Read the traceback, find the file, and — following this repo's
       established Feathers workflow — write a characterization spec that
       reproduces the failure against the *current* code, confirm it's red,
       then fix and confirm green before committing.
     - `WORKER/INFRA` (`ProcessPrunedError`, heartbeat timeout): the job's
       *code* isn't necessarily wrong — the worker process died mid-job
       (OOM, machine sleep, manual restart, terminal closed). Don't "fix" this
       with a code change. If it's clustered across many unrelated job
       classes in the same time window, the problem is the worker process
       itself not staying up — check whether `bin/jobs` (or however this
       app's SolidQueue worker is started) is actually running continuously,
       not just whatever background job you happened to trigger. If it's
       isolated to one job class, look at whether that job is unusually
       long-running or memory-heavy.
     - `INVESTIGATE`: anything else — read the actual error before deciding.
   - **Recurring task schedule** — cross-check against volume: if
     `fetch_all_jobs` runs every 6 hours but no new postings appeared in the
     last 24h, something in that chain is broken even if no exception was
     raised (silent failure / early return / API returning empty).

3. **Report honestly.** Say what's actually observed — don't round a "3 in the
   last 24h, 765 in the last 7 days" into either "it's broken" or "it's fine"
   without noting the ambiguity (could be a slow day, could be a stalled
   pipeline — the failed-job breakdown is what disambiguates it).

4. **Only fix `CODE BUG` findings as part of this skill.** `WORKER/INFRA`
   findings are an operational/infrastructure question (is a process running
   continuously on this machine) — surface them clearly but don't guess at a
   code change to paper over a dead worker.

## Related scripts

- **One JobPosting's downstream pipeline** — after a promote or a single
  scrape, `bin/rails runner .claude/skills/pipeline-health/scripts/job_posting_pipeline_status.rb <id> [id...]`
  reports that posting's `ai_category`/`embedding`/`latitude`/`longitude` plus
  any matching SolidQueue job/failure rows. SolidQueue prunes finished job
  rows fast on this box, so the JobPosting's own fields are the source of
  truth, not the job history.
- **Local LLM server health** — `bin/rails runner .claude/skills/pipeline-health/scripts/check_local_llm.rb`
  checks both the chat (`OLLAMA_API_BASE`) and embed (`OLLAMA_EMBED_API_BASE`)
  llama-server endpoints are reachable, and that the embed server's actual
  output dimension matches `JobPosting.embedding`'s `vector(N)` schema column.
  A mismatch here silently fails every embedding save (`ActiveRecord::RecordInvalid`,
  caught and logged by `JobBoards::Embedder`, never raised) — this exact
  failure mode is why the script exists. The embed server is a zdots-managed
  service; if it's misconfigured, `zdots-issue`, don't reconfigure it here.

## Non-goals

This is a snapshot, not monitoring. It doesn't set up alerting or dashboards
— that's Phase 5 of the modernization plan (OTel spans + `o2_slow`/`o2_errors`
queries once ingestion code emits real spans, particularly for the four
Playwright scrapers which are currently untraced).
