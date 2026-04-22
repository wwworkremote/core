# WWWorkRemote Ingestion Assistant

Chrome extension that captures structured job data from third-party job boards and syncs it back into your local WWWorkRemote Rails application. Open a job posting from inside the app, let the extension extract everything it can find, review and fill in any gaps in the side panel, then submit with one click.

---

## How it works

1. **Trigger from the app** — click *Source & Enrich* on any job posting in WWWorkRemote. The app opens the source URL with `?wwr_id=NNN` appended.

2. **Content script activates** — `content.js` detects the `wwr_id` parameter, shows the overlay badge (`Synthesis_Link`), auto-expands any truncated description ("Show more"), waits for SPA content to render, then runs the extraction chain.

3. **Extraction chain runs** — four levels in priority order:
   | Level | Source | Confidence |
   |-------|--------|------------|
   | 1 | JSON-LD `<script type="application/ld+json">` — Schema.org `JobPosting` | High — structured, immune to selector drift |
   | 2 | Provider CSS selectors — board-specific rules per supported site | Medium |
   | 3 | Open Graph / meta tags — `og:title`, `og:description`, canonical URL | Low |
   | 4 | Generic heuristics — `<main>`, `<article>`, `h1` | Low |

   Results are merged (JSON-LD fields take precedence) and logged to the browser console under `[WWWR]`.

4. **Side panel opens** — extracted data is stored in `chrome.storage.session` and the panel opens automatically. Every supported field is shown: pre-filled if extracted, empty and ready for manual entry if not.

5. **Review and submit** — edit any field, paste missing data, then click **Submit to WWWorkRemote**. The panel sends the edited form data back through the background worker to the content script, which posts to the Rails API with the full live DOM attached.

---

## Side panel fields

Fields with a **green dot** were extracted from the page. Fields with a **hollow dot** were not found and are ready for manual entry or paste.

| Section | Fields |
|---------|--------|
| Core | Title *(required)*, Company, Location, Remote |
| Job Details | Employment Type, Experience, Apply URL |
| Compensation | Salary Min / Max, Currency, Per (year/month/hour), or raw salary text |
| Description | Plain-text textarea with live word count |
| Timing | Posted date, Expires date |
| Skills & Tags | Comma-separated tags |

The original `description_html` is preserved and included in the API payload even though the editable field shows plain text.

---

## Supported job boards

| Board | Auto-expand | SPA wait | JSON-LD |
|-------|-------------|----------|---------|
| LinkedIn | ✓ | ✓ | — |
| Indeed | ✓ | ✓ | — |
| Adzuna | — | ✓ | ✓ |
| WeWorkRemotely | — | ✓ | — |
| RemoteOK | — | ✓ | — |
| Greenhouse | — | ✓ | ✓ |
| Lever | — | ✓ | — |
| Workday | — | ✓ (10 s) | ✓ |
| Ashby | — | ✓ | ✓ |
| SmartRecruiters | — | ✓ | ✓ |
| Wellfound | — | ✓ | — |
| *Generic fallback* | — | — | ✓ (attempted on all) |

---

## Installation

**Requirements:** Chrome 116+ (side panel auto-open requires 116; panel itself works on 114+).

1. Open `chrome://extensions`
2. Enable **Developer mode** (top-right toggle)
3. Click **Load unpacked** and select this `extension/` directory
4. Pin the *WWWorkRemote Ingestion Assistant* extension to your toolbar

After any code change: click the **↺ reload** button on the extension card in `chrome://extensions`.

---

## Configuration

Click the extension icon in the toolbar to open the popup. The **API endpoint** field sets the Rails server URL used for all sync calls. Default is `http://localhost:3010`. Change this if your server runs on a different port or host and click **SAVE** (or press Enter).

The value is stored in `chrome.storage.local` and persists across browser sessions.

---

## File inventory

| File | Role |
|------|------|
| `manifest.json` | MV3 manifest — permissions, host rules, entry points |
| `content.js` | Content script — overlay UI, extraction chain, API submission |
| `background.js` | Service worker — panel state relay via `chrome.storage.session` |
| `sidepanel.html` | Side panel markup — Dracula Pro styled review form |
| `sidepanel.js` | Side panel logic — populates fields, reads form, submits |
| `popup.html` | Toolbar popup — API URL configuration UI |
| `popup.js` | Popup logic — reads/writes `apiUrl` in `chrome.storage.local` |
| `icons/` | Extension icons (16/48/128 px) |

---

## Message flow

```
content.js ──OPEN_PANEL──► background.js ──storage.session.set──► sidepanel.js
                                      └──sidePanel.open()

sidepanel.js ──SUBMIT_JOB──► background.js ──PANEL_SUBMIT──► content.js ──POST──► Rails API
```

---

## API payload

`POST /api/job_postings/:id/enrich`

```json
{
  "id": "42",
  "url": "https://jobs.lever.co/acme/senior-rails-engineer",
  "title": "document.title",
  "provider": "lever",
  "html": "<full live DOM at submit time>",
  "extracted": {
    "title": "Senior Rails Engineer",
    "company": "Acme Corp",
    "location": "Remote — US",
    "remote": true,
    "employment_type": "FULL_TIME",
    "experience": "5+ years",
    "apply_url": "https://jobs.lever.co/acme/…/apply",
    "salary_min": 150000,
    "salary_max": 190000,
    "salary_currency": "USD",
    "salary_unit": "YEAR",
    "description_text": "…plain text edited by user…",
    "description_html": "…original HTML from page…",
    "posted_at": "2026-04-01",
    "valid_through": "2026-06-01",
    "skills": "ruby, rails, postgresql, remote",
    "_method": "json_ld",
    "_confidence": "high"
  }
}
```

---

## Console logging

All extension logs are prefixed `[WWWR HH:MM:SS.mmm]` — filter the DevTools console by `[WWWR]` to isolate them.

| Color | Meaning |
|-------|---------|
| Purple | Informational |
| Green `✓` | Success |
| Yellow `⚠` | Warning (low word count, fallback used) |
| Red `✗` | Error |

---

## Debugging

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Overlay does not appear | URL missing `?wwr_id=NNN` | Add parameter or use *Source & Enrich* from the app |
| Side panel opens empty | Extension needs reload after code change | Click ↺ in `chrome://extensions` |
| Description field empty | SPA not finished rendering | Wait a moment and click **↗ OPEN REVIEW PANEL** again |
| "Panel unavailable" in overlay | Chrome < 116, or extension not loaded | Check Chrome version; reload extension |
| Submit returns 404 | Rails not running or wrong port | Check API endpoint in popup |
| Submit returns timeout | Rails server slow or unreachable | Verify `bin/rails server` is running |
| Word count red (< 50 words) | Description truncated | Look for "Show more" button on the page; extension auto-clicks it on load |

---

## Backend requirement

The extension posts to `POST /api/job_postings/:id/enrich` in the Rails app. The endpoint receives both the raw `html` (full live DOM) and the structured `extracted` object. Use `extracted` fields preferentially — they have already been cleaned, normalised, and reviewed by the user.
