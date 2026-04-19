✦ Summary
   1. Port: 3010 (Falcon, Puma, ActionMailer). Standardized on http://localhost:3010.
   2. Schedule: Standardized on **Solid Queue**. Recurring tasks in `config/recurring.yml`.
   3. Unified Ingestion: HackerNews + **Email Ingestion** use `JobBoards::Document` pattern.
   4. **Email Ingestion**:
      - Auto-scan `.eml` from Indeed, LinkedIn, Adzuna.
      - Tiered Fetch: Faraday (static) -> **Playwright** (dynamic/blocked).
      - Provenance: Link jobs to `Message-ID` + file path.
      - Scheduled: `EmailIngestion::ScanJob` hourly in `recurring.yml`.
   5. AI Orchestration: `RubyLLM` + **Qwen 2.5 Coder (llama.cpp)**.
      - Default local provider prioritization in `llm_chats`.
      - Guardrails pipeline for context protection.
   6. OTel: Full tracing via OpenTelemetry (LGTM stack compatible).
   7. Interface: Native **Dracula Pro** Admin Dashboard.
      - Replaced Avo with high-density, framework-independent Rails views.
      - Integrated Background Pipeline (Solid Queue) monitoring.
      - Integrated Pipeline Intelligence (Chartkick/Chart.js).
   8. Runtime: Ruby 4.0.2 / Rails 8.0.x.

  Restart Plan
   1. **Verify Email Ingestion**:
      - Place `.eml` in `~/.wwworkremote/indeed/`.
      - Run `bin/rake eml:scan`. Verify `EmailImportRecord` + `JobPosting`.
      - Check logs for `fetch_mode` (static vs playwright).
   2. **Verify AI**: 
      - Initiate chat at `/llm_chats/new` (Default: Local Qwen).
      - Run `HackerNews::FetchLatestWorker`, check AI classification tags.
   3. **Infrastructure**:
      - Ensure `llama.cpp` is running on `:8080`.
      - Verify Solid Queue dashboard at `/admin/jobs`.
   4. **Analytics**: 
      - Check `/admin/analytics` for pipeline health visualizations.

  Last Updated: April 19, 2026 (Refined by Gemini)
