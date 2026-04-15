✦ Summary of Changes
   1. Port Reconfiguration: Moved application to port 3010 (Puma, Docker, ActionMailer) to avoid local conflicts.
   2. Scheduling Consolidation: Removed `whenever` and migrated all tasks to `sidekiq-cron` via `config/schedule.yml`.
   3. Unified Ingestion: HackerNews fetcher now uses `JobBoards::Document` pattern, ensuring jobs sync to the dashboard.
   4. AI Categorization: Integrated `RubyLLM` with Llama 3.2 (Ollama) to automatically categorize and tag new job postings.
   5. Observability: Added OpenTelemetry tracing to the `Categorizer` service with domain-specific attributes.
   6. Tooling Cleanup: Removed `database_cleaner`, `reek`, `fasterer`, and `rails_best_practices`. Consolidated linting into RuboCop.
   7. Engine Purge: Deleted the redundant `blorgh` engine.
   8. Runtime Update: Updated Ruby version to 4.0.2 in Gemfile and lockfile.

  Plan for Restart
  Upon restart, you can pick up from these points:
   1. Verify AI Categorization: Run `HackerNews::FetchLatestWorker` and verify `JobPosting` records are tagged.
   2. Contract Tests: Implement Live Contract tests in `spec/contracts/` for all external feeds.
   3. Dashboard UI: Verify that the Avo dashboard correctly filters jobs by the new AI-generated categories.
   4. OpenTelemetry: Ensure `categorize_job` spans are visible in Jaeger.

  All changes have been committed and verified with a boot smoke test.
