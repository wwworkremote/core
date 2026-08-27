# WWWorkRemote Ingestion Assistant

Current unpacked build: `1.26.0`.

Keyboard shortcuts: `Ctrl+Shift+Y` (macOS: `Command+Shift+Y`) or alternate `Option+Shift+Y` opens the panel for the active tab. Configure them at `chrome://extensions/shortcuts` if Chrome reports a conflict. (`Option` is Chrome's `Alt` key.)

Chrome extension that captures structured job data from third-party job boards and syncs it back into your local WWWorkRemote Rails application. Open a job posting from inside the app, let the extension extract everything it can find, review and fill any gaps in the side panel, then submit with one click.

---

## How it works

1. **Trigger from the app** — click *Source & Enrich* on any job posting. The app opens the source URL with `?wwwr_id=NNN` appended.

2. **Content script activates** — `content.js` detects `wwwr_id` (and accepts legacy `wwr_id`), shows the overlay badge, auto-expands truncated descriptions, waits for SPA content to render, then runs the extraction chain.

3. **Extraction chain runs** — four levels in priority order:

   | Level | Source | Confidence |
   |-------|--------|------------|
   | 1 | JSON-LD `<script type="application/ld+json">` — Schema.org `JobPosting` | High |
   | 2 | Provider CSS selectors — board-specific rules per supported site | Medium |
   | 3 | Open Graph / meta tags — `og:title`, `og:description` | Low |
   | 4 | Generic heuristics — `<main>`, `<article>`, `h1` | Low |

   Fields are merged null-safely: a `null` value in a higher-priority source never overwrites a real value from a lower one.

4. **Side panel opens** — extracted data is stored in `chrome.storage.session` and the panel opens automatically. Every field is shown — pre-filled if extracted, empty and ready for manual entry if not.

5. **Review and submit** — edit any field, paste missing data, then click **Submit to WWWorkRemote**. If the description looks truncated (low word count warning), expand content on the job page manually and click **↺ Re-read desc**.

---

## Side panel fields

### Application cockpit

On a tracked Workday application page (`?wwwr_id=NNN`), the side panel also
shows an application cockpit. Choose one of the canonical resume personas
published by `just3ws.localhost`, edit the proposed value, and click **Fill**
for each visible field. Workday controls are discovered per page because their
generated DOM ids are not durable selectors. Filling is always explicit and
never submits the application. Each successful fill is saved against the
tracked WWWorkRemote application with its field label, value, source, and page
URL. The selected persona and personal profile are snapshotted on that
application so later canonical-resume edits do not rewrite history.

Each application field also has a **Map/Remap** action. Click it, click the
corresponding field on the live Workday page, then confirm the semantic source
such as `profile.email`, `persona.positions[].title`, or `application.question`.
Mappings are append-only and retain page/step context plus a compact element
descriptor, allowing later tooling to learn stable associations and noise.

| Indicator | Meaning |
|-----------|---------|
| Green dot | Extracted from page |
| Hollow dot | Not found — ready for manual entry or paste |

| Section | Fields |
|---------|--------|
| Core | Title *(required)*, Company, Location, Remote |
| Job Details | Employment Type, Experience, Apply URL |
| Compensation | Salary Min / Max, Currency, Per (year/month/hour), raw salary text fallback |
| Description | Plain-text textarea, live word count (green ≥200, yellow ≥50, red <50) |
| Timing | Posted date, Expires date |
| Skills & Tags | Comma-separated |
| Additional Details *(collapsible)* | Education, Qualifications, Responsibilities, Benefits |

**Re-read controls:**
- **↺ Re-read page** (header) — re-runs the full extraction chain against the current page state. Use after manually expanding content or waiting for a slow SPA.
- **↺ Desc** (header) / **↺** (next to description field) — re-reads only the description field without touching your other edits.

**Staleness banner:** if you navigate to a different job in the same tab (SPA navigation), a yellow banner appears at the top of the panel warning that the data may be from the previous page. Click **↺ Re-read page** in the banner to refresh.

---

## Authentication

The extension sends HTTP Basic Auth credentials to the Rails API. Set your credentials once in the popup:

1. Click the extension icon in the toolbar
2. Enter the **API endpoint** (default: `http://localhost:31000`)
3. Enter your **Admin email** and **Admin password** (matching `ADMIN_EMAIL` / `ADMIN_PASSWORD` in Rails `.env`)
4. Click **SAVE** (or press Enter)

Credentials are stored in `chrome.storage.local` (local to this browser profile, not synced). The password field never re-populates on open — a `(saved)` placeholder confirms it is set.

---

## Supported job boards

| Board | Auto-expand | SPA wait | JSON-LD |
|-------|-------------|----------|---------|
| LinkedIn | ✓ | ✓ | — |
| Indeed | ✓ | ✓ | — |
| Adzuna | — | ✓ | ✓ |
| WeWorkRemotely | — | ✓ | — |
| RemoteOK | — | ✓ | — |
| Greenhouse | ✓ | ✓ | ✓ |
| Lever | ✓ | ✓ | — |
| Workday | ✓ | ✓ (10 s) | ✓ |
| Ashby | — | ✓ | ✓ |
| SmartRecruiters | — | ✓ | ✓ |
| Wellfound | ✓ | ✓ | — |
| *Generic fallback* | — | — | ✓ (attempted on all) |

---

## Date handling

Dates are parsed flexibly and shown as YYYY-MM-DD in the date pickers. Accepted formats include:

- ISO 8601: `2026-04-01`, `2026-04-01T00:00:00Z`
- Natural language: `April 1, 2026`, `Apr 1 2026`
- Ordinals: `September 9th` (year defaults to current year if absent)
- Abbreviations: `Sept. 9th`, `Feb. 28th`
- Relative: `today`, `yesterday`, `3 days ago`, `2 weeks ago`, `1 month ago`
- Unix timestamps (ms or s)

When a date string can't be parsed, the field is left empty and the original string is shown below the input so you can enter it manually.

---

## Installation

**Requirements:** Chrome 116+ (side panel auto-open requires 116; panel itself works on 114+).

1. Open `chrome://extensions`
2. Enable **Developer mode** (top-right toggle)
3. Click **Load unpacked** and select this `extension/` directory
4. Pin the *WWWorkRemote Ingestion Assistant* extension to the toolbar
5. Open the popup and enter your API endpoint and admin credentials

After any code change: click the **↺ reload** icon on the extension card in `chrome://extensions`.

---

## File inventory

| File | Role |
|------|------|
| `manifest.json` | MV3 manifest — permissions, host rules, entry points |
| `content.js` | Content script — overlay UI, extraction chain, API submission |
| `background.js` | Service worker — panel state relay, REEXTRACT relay |
| `sidepanel.html` | Side panel markup — Dracula Pro styled review form |
| `sidepanel.js` | Side panel logic — populates fields, reads form, submits |
| `popup.html` | Toolbar popup — API URL + credentials configuration |
| `popup.js` | Popup logic — reads/writes config in `chrome.storage.local` |
| `PLAN.md` | Gap audit, execution status, and backend questions |
| `icons/` | Extension icons (16/48/128 px) |

---

## Message flow

```
content.js ──OPEN_PANEL──────────► background.js ──storage.set──► sidepanel.js
                                         └──sidePanel.open()

sidepanel.js ──SUBMIT_JOB──────────► background.js ──PANEL_SUBMIT──► content.js ──POST──► Rails
sidepanel.js ──REEXTRACT(all)──────► background.js ──REEXTRACT──► content.js ──notifyPanel──► storage
sidepanel.js ──REEXTRACT(desc)─────► background.js ──REEXTRACT──► content.js ──UPDATE_DESCRIPTION──► storage
content.js   ──UPDATE_DESCRIPTION──► background.js ──storage.set (desc patch only)
```

---

## API payload

### 1. Enrich Existing Job
`POST /api/v0/job_postings/:id/enrich`
Used when triggered from the app via `?wwwr_id=NNN`.

### 2. Submit New Job (Universal)
`POST /api/v0/job_postings`
Used to ingest a job from any board, even if not already in the WWWorkRemote database.

**Payload Structure (JSON):**
```json
{
  "title": "Senior Rails Engineer",
  "company": "Acme Corp",
  "location": "Remote",
  "target_url": "https://example.com/job/123",
  "body": "Full job description...",
  "data": {
    "salary_min": 150000,
    "salary_max": 200000,
    "provider": "generic",
    "skills": ["ruby", "rails"]
  }
}
```

The API uses the `target_url` to generate a unique `signature` and will upsert the record accordingly.

---

## Console logging

Filter DevTools by `[WWWR]` to isolate extension logs.

| Color | Meaning |
|-------|---------|
| Purple | Informational |
| Green `✓` | Success |
| Yellow `⚠` | Warning |
| Red `✗` | Error |

---

## Debugging

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Overlay does not appear | URL missing `?wwwr_id=NNN` | Use *Source & Enrich* from the app |
| Side panel opens empty | Extension needs reload | Click ↺ in `chrome://extensions` |
| 401 Unauthorized on submit | Credentials not set or wrong | Open popup → enter email + password → SAVE |
| Description empty or truncated | SPA not loaded / content hidden | Click ↺ Re-read page or ↺ Desc after expanding manually |
| Staleness banner appears | SPA navigation detected in same tab | Click ↺ Re-read page in banner |
| Date field empty with "Original: …" | Date string format not recognised | Enter the date manually in the field |
| "Panel unavailable" in overlay | Chrome < 116 or extension not loaded | Check Chrome version; reload extension |
| Submit returns 404 | Rails not running or wrong port | Check API endpoint in popup |
| Submit returns timeout | Rails server unreachable | Verify `bin/rails server` is running |
| Word count red (< 50) | Description truncated | Expand "Show more" on the page, then click ↺ Desc |

---

## Backend requirements

See `PLAN.md` for the full gap analysis. Key pending items:

- **B2 (High value):** The `enrich` action currently ignores the `extracted` payload and re-runs CSS extraction. It should use `extracted` fields (reviewed by user) as the primary data source.
- **B3:** `detect_provider` in the controller only handles LinkedIn, Indeed, and Adzuna. The extension now sends `provider` explicitly — use that.
- **CORS:** Likely not needed (extension `host_permissions` bypasses CORS for content script fetches). Confirm by testing; if `CORS error` appears, see `PLAN.md` § B1 for the `cors.rb` snippet.
