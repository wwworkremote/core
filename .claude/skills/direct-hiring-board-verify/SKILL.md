---
name: direct-hiring-board-verify
description: "Verify a single company's board-based ingestion adapter (ADP, Workday, Greenhouse, Lever) end-to-end before adding it to db/seeds.rb or a Query's boards list. Use when onboarding a new direct-hiring-page company, when a board seems to have gone silent, or when the user names a specific company and asks 'does this work' / 'can we track this company directly'."
metadata:
  version: 1.0.0
---

# Direct-Hiring Board Verification

This project's stated ingestion priority is direct company career pages over generic job
boards — the more companies wired up, the more relevant and timely the data. Onboarding a new
company means guessing its ATS's tenant/site slug from its career-site URL, which is easy to get
subtly wrong (wrong tenant, wrong path segment). This skill is the fast feedback loop for that,
instead of waiting for the next scheduled fetch cycle to find out.

## Steps

1. **Identify the ATS and slug(s) from the company's own career-site URL:**
   - ADP: `myjobs.adp.com/<slug>` → the slug is everything after `myjobs.adp.com/`.
   - Workday: `<tenant>.<wd>.myworkdayjobs.com/<site>` → three separate values
     (e.g. `myhrhome.wd1.myworkdayjobs.com/OneMainCareers` → tenant `myhrhome`, wd `wd1`,
     site `OneMainCareers`).
   - Greenhouse: `job-boards.greenhouse.io/<slug>` or `boards.greenhouse.io/<slug>`.
   - Lever: `jobs.lever.co/<slug>`.

2. **Run `bin/verify_board` against development** (never test — see
   `docs/agents/bin-script-conventions.md` for why; the script refuses to run under
   `RAILS_ENV=test` on its own):
   ```
   RAILS_ENV=development bin/verify_board adp <slug>
   RAILS_ENV=development bin/verify_board greenhouse <slug>
   RAILS_ENV=development bin/verify_board lever <slug>
   RAILS_ENV=development bin/verify_board workday <tenant> <wd> <site>
   ```
   This calls the adapter's real `fetch_granular` directly — bypassing SolidQueue and the
   adapter's cooldown — and reports how many new `JobBoards::Document` rows resulted.

3. **Interpret the result:**
   - New rows with sane-looking titles → the slug is right. Add it to the company's
     `JobBoards::Query#data["boards"]` (see `db/seeds.rb` for the existing pattern) so it's
     picked up on the adapter's normal schedule going forward.
   - Zero new rows → could mean the company genuinely has no open reqs right now (confirm by
     opening the career-site URL directly), or the slug/tenant/site is wrong. Don't assume
     either without checking the actual page.
   - A raised error → read it; a 4xx/5xx from the ATS's own API usually means a wrong slug, not
     a code bug in the adapter (all four adapters were live-verified against real tenants when
     built — see TASK-45 and the ADP/Workday adapter work in git history).

4. **If a whole new ATS platform is involved** (not ADP/Workday/Greenhouse/Lever), this skill
   doesn't cover writing a new adapter — that's real implementation work. Look at
   `packages/ingestion/app/services/workday/fetcher.rb` as the reference shape (a `call`
   entrypoint for the scheduled path, a `fetch_granular(board, term, source_id, query_id)`
   entrypoint for direct verification, writes flow through `JobBoards::DocumentUpserter`) and
   file a task for it rather than improvising against Syncer/AttributeMapper without a plan.

## Non-goals

This doesn't decide *which* companies to onboard — that's a judgment call based on career
relevance, not something to automate. It only answers "does this specific slug actually work."
