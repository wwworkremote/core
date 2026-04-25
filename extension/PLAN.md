#<--rubocop/md--># Extension — Gaps, Plan, and Backend Questions
#<--rubocop/md-->
#<--rubocop/md-->Last updated: 2026-04-22
#<--rubocop/md-->
#<--rubocop/md-->---
#<--rubocop/md-->
#<--rubocop/md-->## Concerns audited
#<--rubocop/md-->
#<--rubocop/md-->### Critical — breaks on first real use
#<--rubocop/md-->
#<--rubocop/md-->| # | Issue | Status |
#<--rubocop/md-->|---|-------|--------|
#<--rubocop/md-->| C1 | **No authentication** — fetch sends no credentials; Rails HTTP Basic Auth rejects with 401 | ✅ Fixed (popup credential fields + Authorization header) |
#<--rubocop/md-->| C2 | **CORS** — `config/initializers/cors.rb` is fully commented out; `rack-cors` gem is installed but inert | ⚠ Backend approval needed (see Backend section) |
#<--rubocop/md-->
#<--rubocop/md-->> **CORS note:** Chrome extensions with `host_permissions` for the target origin bypass CORS in content scripts. `http://localhost:*/*` is declared in `manifest.json`, so the fetch from a content script to `localhost:3010` likely works without server-side CORS headers. **Requires confirmation by testing.** If requests still fail with `CORS error` in the console, activate `cors.rb` — details in Backend section below.
#<--rubocop/md-->
#<--rubocop/md-->---
#<--rubocop/md-->
#<--rubocop/md-->### Significant — real functional gaps
#<--rubocop/md-->
#<--rubocop/md-->| # | Issue | Status |
#<--rubocop/md-->|---|-------|--------|
#<--rubocop/md-->| S1 | **`canonical_url` used as `apply_url` fallback** — canonical = listing page URL, not application form | ✅ Fixed |
#<--rubocop/md-->| S2 | **No re-extract trigger** — if SPA content loads after extraction, or user manually expands, no way to refresh | ✅ Fixed (Re-read page + Re-read description buttons) |
#<--rubocop/md-->| S3 | **HTML payload size unchecked** — some job pages exceed 3 MB; no guard before sending | ✅ Fixed (512 KB cap with truncation notice) |
#<--rubocop/md-->| S4 | **Null values from JSON-LD overwrite valid CSS values** — `{...jsonLd}` spreads `title: null` even when CSS had a real title | ✅ Fixed (null-safe merge) |
#<--rubocop/md-->| S5 | **Date parsing inflexible** — rejects "Sept. 9th", "3 days ago", "Posted today", dates without year | ✅ Fixed (robust parser) |
#<--rubocop/md-->| S6 | **SPA navigation not detected** — navigating to another job in same tab silently stales the panel | ✅ Fixed (pushState/popState watch + staleness banner) |
#<--rubocop/md-->| S7 | **Hidden extracted fields (education, qualifications, responsibilities, benefits)** — extracted but invisible; user can't verify or edit | ✅ Fixed (collapsible Additional Details section) |
#<--rubocop/md-->| S8 | **Auto-expand only covers LinkedIn and Indeed** — Greenhouse, Lever, Workday, Wellfound have expandable descriptions that get captured truncated | ✅ Fixed (added expanders for 4 more boards) |
#<--rubocop/md-->
#<--rubocop/md-->---
#<--rubocop/md-->
#<--rubocop/md-->### Minor / design
#<--rubocop/md-->
#<--rubocop/md-->| # | Issue | Notes |
#<--rubocop/md-->|---|-------|-------|
#<--rubocop/md-->| M1 | Content script runs on `<all_urls>` and bails immediately on 99% of pages | Acceptable; narrowing requires dynamic injection which adds complexity |
#<--rubocop/md-->| M2 | `description_text` edited by user but `description_html` is original — potential inconsistency | Backend should prefer `description_text` when present. See Backend note. |
#<--rubocop/md-->| M3 | No success-state navigation — after submit user must manually return to Rails | Future: add link to job posting URL in submission response |
#<--rubocop/md-->
#<--rubocop/md-->---
#<--rubocop/md-->
#<--rubocop/md-->## Backend — pending approval
#<--rubocop/md-->
#<--rubocop/md-->These require changes **outside** `extension/`. Read-only access confirmed; no changes made.
#<--rubocop/md-->
#<--rubocop/md-->### B1 — CORS configuration ✅ Done
#<--rubocop/md-->
#<--rubocop/md-->**File:** `config/initializers/cors.rb`
#<--rubocop/md-->
#<--rubocop/md-->The initializer is fully commented out. Because the extension has `host_permissions` for `http://localhost:*/*`, Chrome bypasses CORS for content script fetches to localhost. Test with the extension running — if the DevTools console shows a `CORS error`, uncomment and configure:
#<--rubocop/md-->
#<--rubocop/md-->```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # chrome-extension:// origins vary by installation; allow localhost for local dev.
    # For production use a specific allowlist.
    origins(%r{\Achrome-extension://})

    resource '/api/*',
             headers: :any,
             methods: %i[get post options],
             credentials: false
  end
end
#<--rubocop/md-->```
#<--rubocop/md-->
#<--rubocop/md-->### B2 — `enrich` action ignores `extracted` payload ✅ Done
#<--rubocop/md-->
#<--rubocop/md-->**File:** `app/controllers/api/job_postings_controller.rb`
#<--rubocop/md-->
#<--rubocop/md-->The current `enrich` action discards the structured `extracted` object sent by the extension and re-runs `CanonicalJobExtractor` on the raw HTML. This means:
#<--rubocop/md-->- User-reviewed edits are thrown away
#<--rubocop/md-->- Only `body` (description) is updated; title/company/location/salary are never written
#<--rubocop/md-->- `detect_provider` only handles `linkedin`, `indeed`, `adzuna` — the extension supports 11 boards
#<--rubocop/md-->
#<--rubocop/md-->**Proposed change:**
#<--rubocop/md-->
#<--rubocop/md-->```ruby
def enrich
  job_posting = JobPosting.find(params[:id])
  extracted   = params[:extracted].to_h
  provider    = params[:provider] || detect_provider(params[:url].to_s)

  # Prefer user-reviewed structured data over re-extraction
  if extracted['description_text'].present?
    markdown_body = ReverseMarkdown.convert(
      extracted['description_html'].presence || extracted['description_text'],
      unknown_tags: :bypass, github_flavored: true
    ).strip
  else
    job_data = JobFetchers::CanonicalJobExtractor.new(params[:html], params[:url], provider).call
    markdown_body = (ReverseMarkdown.convert(job_data[:description], unknown_tags: :bypass,
github_flavored: true).strip if job_data[:description].present?)
  end

  return render json: { success: false, error: 'No description found.' },
status: :unprocessable_entity unless markdown_body

  attrs = {
    body: markdown_body,
    crawl_status: 'enriched',
    enriched_at: Time.current
  }
  attrs[:title]   = extracted['title']   if extracted['title'].present?
  attrs[:company] = extracted['company'] if extracted['company'].present?
  # Map additional fields into job_posting.data JSONB as appropriate

  job_posting.update!(attrs)
  JobBoards::Categorizer.new(job_posting).call
  JobBoards::Embedder.new(job_posting).call

  render json: { success: true, message: "Job ##{job_posting.id} enriched." }
end
#<--rubocop/md-->```
#<--rubocop/md-->
#<--rubocop/md-->### B3 — `detect_provider` only knows 3 boards ✅ Done
#<--rubocop/md-->
#<--rubocop/md-->**File:** `app/controllers/api/job_postings_controller.rb`
#<--rubocop/md-->
#<--rubocop/md-->`detect_provider` checks for `linkedin`, `indeed`, `adzuna` only. The extension sends `provider` explicitly — use that instead of re-detecting:
#<--rubocop/md-->
#<--rubocop/md-->```ruby
provider = params[:provider].presence || detect_provider(params[:url].to_s)
#<--rubocop/md-->```
#<--rubocop/md-->
#<--rubocop/md-->---
#<--rubocop/md-->
#<--rubocop/md-->## Questions to resolve before B2
#<--rubocop/md-->
#<--rubocop/md-->1. Does `job_posting` have `title` and `company` columns, or are those stored in `data` JSONB?
#<--rubocop/md-->2. Do `salary_min`, `salary_max`, `salary_currency`, `employment_type`, `remote` map to columns or to `data` JSONB?
#<--rubocop/md-->3. Should `enriched_at` be set again on re-submission, or only on first enrich?
#<--rubocop/md-->4. Should re-submission overwrite an already-enriched posting, or only fill blank fields?
