✦ Summary
   1. Port: 3010 (Puma, Docker, ActionMailer). No local conflicts.
   2. Schedule: Migrated `whenever` to `sidekiq-cron` (`config/schedule.yml`, `recurring.yml`).
   3. Unified Ingestion: HackerNews + **Email Ingestion** use `JobBoards::Document` pattern.
   4. **Email Ingestion**:
      - Auto-scan `.eml` from Indeed, LinkedIn, Adzuna.
      - Tiered Fetch: Faraday (static) -> **Playwright** (dynamic/blocked).
      - Provenance: Link jobs to `Message-ID` + file path.
      - Scheduled: `EmailIngestion::ScanJob` hourly in `recurring.yml`.
   5. AI Categorization: `RubyLLM` + Llama 3.2 (Ollama) categorize/tag jobs.
   6. OTel: Tracing in `Categorizer` service.
   7. Cleanup: Removed `database_cleaner`, `reek`, `fasterer`, `rails_best_practices`. Use RuboCop.
   8. Engine: Deleted `blorgh`.
   9. Runtime: Ruby 4.0.2.

  Restart Plan
   1. **Verify Email Ingestion**:
      - Place `.eml` in `~/.wwworkremote/indeed/`.
      - Run `bin/rake eml:scan`. Verify `EmailImportRecord` + `JobPosting`.
      - Check logs for `fetch_mode` (static vs playwright).
   2. Verify AI: Run `HackerNews::FetchLatestWorker`, check tags.
   3. Tests: Live Contract tests in `spec/contracts/`.
   4. Dashboard: Avo filters for AI categories.
   5. OTel: `categorize_job` spans in Jaeger.

  Changes committed and boot-verified.
